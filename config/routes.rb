Rails.application.routes.draw do
  root 'welcome#index'

  protected_app = Rack::Auth::Basic.new(Resque::Server) do |username, password|
    password === 'test'
  end

  require 'resque/server'
  mount Resque::Server.new, at: '/queue'

  # TODO: make my routes more Rails-y
  get '/login' => 'sessions#new'
  post '/login' => 'sessions#create'
  get '/logout' => 'sessions#destroy'

  resources :notification_subscribers, only: [:index, :show] do
    member do
      post :subscribe
      post :unsubscribe
    end
  end

  resources :monitored_scripts do
    resources :script_changes, only: [:show] do
      member do
        get :content
      end
    end
    resources :notification_subscribers
  end

  get '/script_changes/:hash' => 'script_changes#show', as: :script_change, format: :js
end

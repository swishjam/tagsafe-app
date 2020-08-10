Rails.application.routes.draw do
  root 'welcome#index'

  # config/routes.rb
  resque_web_constraint = lambda do |request|
    # current_user = request.env['warden'].user
    # current_user.present? && current_user.respond_to?(:is_admin?) && current_user.is_admin?
    true
  end

  require 'resque/server'
  constraints resque_web_constraint do
    mount Resque::Server, at: '/queue'
  end

  # TODO: make my routes more Rails-y
  get '/login' => 'sessions#new'
  post '/login' => 'sessions#create'

  resources :monitored_scripts do
    resources :script_changes, only: [:show] do
      member do
        get :content
      end
    end
  end

  get '/script_changes/:hash' => 'script_changes#show', as: :script_change, format: :js
end

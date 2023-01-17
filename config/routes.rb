Rails.application.routes.draw do
  # root 'tags#index'
  root 'containers#index'
  require 'resque/server'
  mount Resque::Server.new, at: '/queue'

  get '/login' => 'sessions#new', as: :new_session
  post '/login' => 'sessions#create'
  get '/logout' => 'sessions#destroy', as: :logout

  resources :registrations, only: [:new, :create]
  get '/register' => 'registrations#new'

  get '/user_invites/:token/accept' => 'user_invites#accept', as: :accept_invite
  post '/user_invites/:token/redeem' => 'user_invites#redeem', as: :redeem_invite

  # get '/releases' => 'releases#all', as: :all_releases

  resources :containers, only: [:index, :create, :update, :new, :show], param: :uid do
    resources :non_third_party_url_patterns, only: [:create, :destroy], param: :uid

    resources :tag_snippets, param: :uid do
      collection do
        get :list
      end
      resources :tags, except: [:new, :delete], param: :uid do
        member do
          get '/settings' => 'tags#edit'
          get :uptime
          get :audits
          get :uptime_metrics
          resources :releases, only: :index, as: :tag_releases
        end
        collection do
          get :select_tag_to_audit
        end
        resources :tag_versions, only: [:show, :index], param: :uid do
          member do
            get :promote
            post :set_as_live_tag_version

            get :audit_redirect
            get :content
            get :git_diff
            get :js
            get '/js.js' => 'tag_versions#js', as: :raw_js
          end
        end
        resources :audits, only: [:show, :index, :new, :create], param: :uid do
          member do
            get :git_diff
          end
        end
      end
    end

    resources :change_requests, only: [:index, :show], param: :tag_version_uid do
      member do
        get :details
        get :git_diff
        post :decide
      end
      collection do
        get :list
      end
    end
    
    resources :user_invites, only: [:new, :create, :index]

    namespace :server_loadable_partials do
      resources :tags, only: :index, param: :uid do
        resources :tag_versions, only: :index, param: :uid do
          member do
            get :diff
          end
        end
      end
    end

    namespace :charts do
      resources :tags, only: [:index, :show], param: :uid
      resources :uptime_checks, only: [:index, :show], param: :uid
      resources :page_loads, only: [:index], param: :uid
    end

    get '/page_performance' => 'page_loads#index'
    get '/settings' => 'settings#global_settings', as: :settings
    get '/settings/team_management' => 'settings#team_management', as: :team_management
    get '/settings/install_script' => 'settings#install_script', as: :install_script

    resources :container_users, only: [:destroy, :index, :show], param: :uid
    # get "/container_users/:uid/destroy_modal" => 'container_users#destroy_modal', as: :destroy_container_user_modal
  end

  get '/admin' => redirect('/admin/performance')
  namespace :admin do
    get '/performance' => 'performance#index'
    get '/executed_step_function/for_obj/:parent_type/:parent_id' => 'executed_step_functions#for_obj'
    resources :containers, only: [:index, :show], param: :uid
    resources :lambda_functions, controller: :executed_step_functions, only: [:index, :show], param: :uid
    resources :aws_event_bridge_rules, only: [:index, :show, :update]
    resources :tag_identifying_data, param: :uid do
      resources :tag_identifying_data_containers, only: :create, param: :uid
    end
  end
end

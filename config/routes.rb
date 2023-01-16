Rails.application.routes.draw do
  root 'tags#index'
  require 'resque/server'
  mount Resque::Server.new, at: '/queue'

  get '/login' => 'sessions#new', as: :new_session
  post '/login' => 'sessions#create'
  get '/logout' => 'sessions#destroy', as: :logout

  get '/demo' => 'welcome#index'

  resources :registrations, only: [:new, :create]
  get '/register' => 'registrations#new'

  resources :container_users, only: [:destroy, :index], param: :uid
  get "/container_users/:uid/destroy_modal" => 'container_users#destroy_modal', as: :destroy_container_user_modal
  resources :user_invites, only: [:new, :create, :index]
  get '/user_invites/:token/accept' => 'user_invites#accept', as: :accept_invite
  post '/user_invites/:token/redeem' => 'user_invites#redeem', as: :redeem_invite

  # get '/change_log' => 'tag_versions#index'
  get '/audit_log' => 'audits#all', as: :audit_log
  get '/test_run_log' => 'test_runs#all', as: :all_test_runs
  get '/uptime' => 'uptime_checks#index'
  # get '/uptime/:tag_uid/chart' => 'uptime_checks#tag_chart', as: :tag_uptime_chart
  get '/uptime/:tag_uid/list' => 'uptime_checks#tag_list', as: :tag_uptime_list
  get '/uptime/list' => 'uptime_checks#container_list', as: :container_uptime_list
  get '/performance' => 'performance#index'
  get '/page_performance' => 'page_loads#index'
  get '/releases' => 'releases#all', as: :all_releases
  resources :releases, only: [] do
    collection do
      get :release_calendar
      # get :rolled_up_release_list
      # get :unrolled_release_list
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

  # get '/alerts' => 'alert_configurations#index', as: :alerts
  # get '/alerts/:uid' => 'triggered_alerts#show', as: :alert
  resources :alert_configurations, only: [:index, :show, :new, :create, :update], param: :uid do
    member do
      get :trigger_rules
      resources :alert_configuration_container_users, only: [:index]
      resources :alert_configuration_tags, only: [:index]
    end
  end
  resources :triggered_alerts, only: [:index, :show], param: :uid

  resources :containers, only: [:create, :update, :new], param: :uid do
    member do
      get '/install' => 'containers#install_script', as: :install_script
    end
    resources :non_third_party_url_patterns, only: [:create, :destroy], param: :uid
  end
  put '/update_current_container/:uid' => 'containers#update_current_container', as: :update_current_container

  resources :tag_snippets, param: :uid do
    collection do
      get :list
    end
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

  resources :honeycombs, only: [:index, :show], param: :uid do
    collection do
      get :chart
    end
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
      # member do
      #   post :apply_to_tags
      # end
      # collection do
      #   post :apply_all_to_tags
      # end
      # resources :tag_image_container_lookup_patterns, only: [:create, :destroy]
    # end
  end

  namespace :server_loadable_partials do
    resources :tags, only: :index, param: :uid do
      resources :tag_versions, only: :index, param: :uid do
        member do
          get :diff
          get :live_comparison
        end
      end
    end
  end

  post '/api/stripe_webhook_receiver' => 'stripe_webhook_receiver#receive'
  post '/api/lambda_event_receiver/success' => 'lambda_event_receiver#success'

  get '/settings' => 'settings#global_settings', as: :settings
  get '/settings/team_management' => 'settings#team_management', as: :team_management
  get '/settings/install_script' => 'settings#install_script', as: :install_script
  # get '/settings/billing' => 'settings#billing'

  namespace :charts do
    resources :tags, only: [:index, :show], param: :uid
    resources :uptime_checks, only: [:index, :show], param: :uid
    resources :page_loads, only: [:index], param: :uid
  end

  # get '/charts/container/:container_uid' => 'charts#tags', as: :container_tags_chart
  # get '/charts/tag/:tag_uid' => 'charts#tag', as: :tag_chart
  # get '/charts/uptime/:container_uid' => 'charts#tag_uptime', as: :tags_uptime_chart
  get '/charts/admin_audit_performance' => 'charts#admin_audit_performance', as: :admin_audit_performance_chart
  get '/charts/admin_lambda_functions' => 'charts#admin_executed_step_functions', as: :admin_executed_step_functions_chart
end

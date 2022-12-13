Rails.application.routes.draw do
  root 'welcome#index'
  get '/__blank' => 'application#__blank'
  get '/pricing' => 'welcome#pricing', as: :pricing
  get '/contact-us' => 'welcome#contact_us', as: :contact_us
  post '/contact' => 'welcome#contact', as: :contact
  # get '/products/performance-audits' => 'welcome#performance_audits'
  # get '/products/functional-tests' => 'welcome#functional_tests'
  # get '/products/release-monitoring' => 'welcome#release_monitoring'
  # get '/products/uptime-monitoring' => 'welcome#uptime_monitoring'

  require 'resque/server'
  mount Resque::Server.new, at: '/queue'

  get '/login' => 'sessions#new'
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
  get '/releases' => 'releases#all', as: :all_releases
  resources :releases, only: [] do
    collection do
      get :release_chart
      get :rolled_up_release_list
      get :unrolled_release_list
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
    resources :page_urls, only: [:update], param: :uid do
      collection do
        post '/create_or_update' => 'page_urls#create_or_update'
      end
    end
    resources :non_third_party_url_patterns, only: [:create, :destroy], param: :uid
  end
  put '/update_current_container/:uid' => 'containers#update_current_container', as: :update_current_container

  resources :functional_tests, param: :uid do
    member do
      get :tags_to_run_on
      post :validate
      patch :toggle_disable
    end
    get '/functional_tests_to_run' => 'functional_tests_to_run#index'
    post '/functional_tests_to_run' => 'functional_tests_to_run#create'
    delete '/functional_test_to_run/:uid' => 'functional_tests_to_run#destroy', as: :destroy_functional_test_to_run
    resources :test_runs, only: [:index, :show], param: :uid do
      member do
        post :retry
      end
    end
  end

  resources :tags, param: :uid do
    collection do
      post :promote
      post '/builder/new' => 'tag_builder#new'
    end
    patch '/builder/update' => 'tag_builder#update'
    get '/builder/resource' => 'tag_builder#resource'
    get '/builder/load_rules' => 'tag_builder#load_rules'
    get '/builder/performance' => 'tag_builder#performance'
    get '/builder/position' => 'tag_builder#position'
    get '/builder/review' => 'tag_builder#review'

    member do
      get :uptime
      get :audits
      get :uptime_metrics
      post :toggle_disable
      resources :releases, only: :index, as: :tag_releases
    end
    collection do
      get :select_tag_to_audit
    end
    get '/general' => 'tags#edit' 
    # get '/preferences' => 'tags#preferences'
    get '/audit_settings' => 'tags#audit_settings'
    get '/notification_settings' => 'tags#notification_settings'

    resources :uptime_regions_to_check, only: [:create, :destroy, :new], param: :uid
    resources :urls_to_audit, only: [:create, :destroy], param: :uid
    resources :tag_versions, only: [:show, :index], param: :uid do
      member do
        get :audit_redirect
        get '/live_comparison' => 'tag_versions#live_comparison'
        get :content
        get :git_diff
        get :js
        get '/js.js' => 'tag_versions#js', as: :raw_js
        get :tagsafe_instrumented_js
        get '/tagsafe_instrumented_js.js' => 'tag_versions#tagsafe_instrumented_js'
      end
    end
    resources :audits, only: [:show, :index, :new, :create], param: :uid do
      member do
        get :performance_audit
        resources :performance_audit_speed_index_result, only: :index
        get :test_runs
        # get '/test_runs/:test_run_id' => 'audits#test_run', as: :test_run
        get :waterfall
        get :git_diff
        get :cloudwatch_logs
        post :make_primary
      end
      resources :individual_performance_audits, only: :index
      get '/performance_stats' => 'individual_performance_audits#index'
      # turbo frame src endpoints
      get '/test_runs_for_audit' => 'test_runs#index_for_audit', as: :test_runs_for_audit
      get '/test_run_for_audit/:uid' => 'test_runs#show_for_audit', as: :test_run_for_audit
      resources :performance_audit_logs, only: :index
      resources :page_load_resources, only: :index
      get '/waterfall' => 'page_load_resources#for_audit'
    end
  end

  resources :honeycombs, only: [:index, :show], param: :uid do
    collection do
      get :chart
    end
  end

  resources :general_configuration, only: [:create, :update], param: :uid

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

  get '/settings' => 'settings#global_settings'
  get '/settings/tag_management' => 'settings#tag_management'
  get '/settings/billing' => 'settings#billing'

  namespace :charts do
    resources :tags, only: [:index, :show], param: :uid
    resources :uptime_checks, only: [:index, :show], param: :uid
  end

  # get '/charts/container/:container_uid' => 'charts#tags', as: :container_tags_chart
  # get '/charts/tag/:tag_uid' => 'charts#tag', as: :tag_chart
  # get '/charts/uptime/:container_uid' => 'charts#tag_uptime', as: :tags_uptime_chart
  get '/charts/admin_audit_performance' => 'charts#admin_audit_performance', as: :admin_audit_performance_chart
  get '/charts/admin_lambda_functions' => 'charts#admin_executed_step_functions', as: :admin_executed_step_functions_chart
end

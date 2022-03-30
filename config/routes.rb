Rails.application.routes.draw do
  root 'welcome#index'

  require 'resque/server'
  mount Resque::Server.new, at: '/queue'

  get '/login' => 'sessions#new'
  post '/login' => 'sessions#create'
  get '/logout' => 'sessions#destroy', as: :logout

  get '/demo' => 'demo#index'

  resources :registrations, only: [:new, :create]
  get '/register' => 'registrations#new'
  
  resources :domain_users, only: [:destroy]
  get "/domain_users/:id/destroy_modal" => 'domain_users#destroy_modal', as: :destroy_domain_user_modal
  resources :user_invites, only: [:new, :create]
  get '/user_invites/:token/accept' => 'user_invites#accept', as: :accept_invite
  post '/user_invites/:token/redeem' => 'user_invites#redeem', as: :redeem_invite

  get '/change_log' => 'tag_versions#index'
  get '/audit_log' => 'audits#all', as: :audit_log
  get '/uptime' => 'tag_checks#index'
  get '/uptime/:tag_id' => 'tag_checks#tag', as: :tag_uptime_data
  get '/performance' => 'performance#index'

  resources :domain_audits, only: [:create, :show]

  get '/alerts' => 'triggered_alerts#index', as: :alerts
  get '/alerts/:id' => 'triggered_alerts#show', as: :alert
  resources :alert_configurations, only: [:show, :create, :update]

  resources :domains, only: [:create, :update, :new] do
    resources :page_urls, only: [:update] do
      collection do
        post '/create_or_update' => 'page_urls#create_or_update'
      end
    end
    resources :non_third_party_url_patterns, only: [:create, :destroy]
  end
  put '/update_current_domain/:uid' => 'domains#update_current_domain', as: :update_current_domain

  resources :functional_tests do
    member do
      get :tags_to_run_on
      post :validate
      patch :toggle_disable
    end
    resources :test_runs, only: [:index, :show] do
      member do
        post :retry
      end
    end
  end

  resources :tags do
    member do
      get :uptime
      get :audits
      patch :disable
      patch :enable
    end
    get '/general' => 'tags#edit' 
    # get '/preferences' => 'tags#preferences'
    get '/audit_settings' => 'tags#audit_settings'
    get '/notification_settings' => 'tags#notification_settings'

    resources :urls_to_audit, only: [:create, :destroy]
    resources :slack_notification_subscribers, only: [:create, :destroy]
    resources :tag_allowed_performance_audit_third_party_urls, only: [:create, :destroy]
    resources :tag_preferences, only: [:edit, :update]
    resources :tag_versions, only: [:show, :index] do
      member do
        get '/live_comparison' => 'tag_versions#live_comparison'
        get :content
        get :git_diff
        get :js
        get '/js.js' => 'tag_versions#js', as: :raw_js
        get :tagsafe_instrumented_js
        get '/tagsafe_instrumented_js.js' => 'tag_versions#tagsafe_instrumented_js'
      end
    end
    resources :audits, only: [:show, :index, :new, :create] do
      member do
        get :performance_audit
        get :test_runs
        # get '/test_runs/:test_run_id' => 'audits#test_run', as: :test_run
        get :page_change_audit
        get :waterfall
        get :git_diff
        get :cloudwatch_logs
        post :make_primary
      end
      resources :individual_performance_audits, only: :index
      get '/performance_stats' => 'individual_performance_audits#index'
      # turbo frame src endpoints
      get '/test_runs_for_audit' => 'test_runs#index_for_audit', as: :test_runs_for_audit
      get '/test_run_for_audit/:id' => 'test_runs#show_for_audit', as: :test_run_for_audit
      resources :page_change_audits, only: :show
      resources :performance_audit_logs, only: :index
      resources :page_load_resources, only: :index
      get '/waterfall' => 'page_load_resources#for_audit'
    end
  end
  resources :default_audit_configuration, only: [:create, :update]

  get '/admin' => redirect('/admin/performance')
  namespace :admin do
    get '/performance' => 'performance#index'
    get '/executed_lambda_function/for_obj/:parent_type/:parent_id' => 'executed_lambda_functions#for_obj'
    resources :lambda_functions, controller: :executed_lambda_functions, only: [:index, :show]
    resources :flags, only: [:index, :show] do
      resources :object_flags
    end
    resources :tag_identifying_data
      # member do
      #   post :apply_to_tags
      # end
      # collection do
      #   post :apply_all_to_tags
      # end
      # resources :tag_image_domain_lookup_patterns, only: [:create, :destroy]
    # end
  end

  namespace :server_loadable_partials do
    resources :tags, only: :index do
      resources :tag_versions, only: :index do
        member do
          get :diff
          get :live_comparison
        end
      end
    end
  end

  resources :stripe_billing_portal, only: :new
  resources :domain_subscription_option, only: [:edit, :update]
  resources :domain_payment_methods, only: [:new, :create]

  post '/api/stripe_webhook_receiver' => 'stripe_webhook_receiver#receive'
  post '/api/lambda_event_receiver/success' => 'lambda_event_receiver#success'

  get '/settings' => 'settings#global_settings'
  get '/settings/tag_management' => 'settings#tag_management'
  get '/settings/billing' => 'settings#billing'
  resources :url_crawls, only: [:index, :show, :create]
  get '/settings/integrations/slack/oauth/redirect' => 'slack_settings#oauth_redirect'

  get '/charts/domain/:domain_id' => 'charts#tags', as: :domain_tags_chart
  get '/charts/tag/:tag_id' => 'charts#tag', as: :tag_chart
  get '/charts/uptime/:domain_id' => 'charts#tag_uptime', as: :tags_uptime_chart
  get '/charts/admin_audit_performance' => 'charts#admin_audit_performance', as: :admin_audit_performance_chart
  get '/charts/admin_lambda_functions' => 'charts#admin_executed_lambda_functions', as: :admin_executed_lambda_functions_chart
end

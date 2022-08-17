Rails.application.routes.draw do
  root 'welcome#index'
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

  get '/demo' => 'demo#index'

  resources :registrations, only: [:new, :create] do
    collection do
      get :domain
    end
  end
  get '/register' => 'registrations#new'
  
  resources :domain_users, only: [:destroy, :index], param: :uid
  get "/domain_users/:uid/destroy_modal" => 'domain_users#destroy_modal', as: :destroy_domain_user_modal
  resources :user_invites, only: [:new, :create, :index]
  get '/user_invites/:token/accept' => 'user_invites#accept', as: :accept_invite
  post '/user_invites/:token/redeem' => 'user_invites#redeem', as: :redeem_invite

  # get '/change_log' => 'tag_versions#index'
  get '/audit_log' => 'audits#all', as: :audit_log
  get '/test_run_log' => 'test_runs#all', as: :all_test_runs
  get '/uptime' => 'uptime_checks#index'
  # get '/uptime/:tag_uid/chart' => 'uptime_checks#tag_chart', as: :tag_uptime_chart
  get '/uptime/:tag_uid/list' => 'uptime_checks#tag_list', as: :tag_uptime_list
  get '/uptime/list' => 'uptime_checks#domain_list', as: :domain_uptime_list
  get '/performance' => 'performance#index'
  get '/releases' => 'releases#all', as: :all_releases
  resources :releases, only: [] do
    collection do
      get :release_chart
      get :rolled_up_release_list
      get :unrolled_release_list
    end
  end

  resources :domain_audits, only: [:new, :create], param: :uid do
    member do
      get :global_bytes_breakdown
      get :individual_bytes_breakdown
      get :performance_impact
      get :speed_index
      get :puppeteer_recording
      get :tag_list
      get :complete
    end
  end
  get '/third_party_impact' => 'domain_audits#show', as: :third_party_impact

  # get '/alerts' => 'alert_configurations#index', as: :alerts
  # get '/alerts/:uid' => 'triggered_alerts#show', as: :alert
  resources :alert_configurations, only: [:index, :show, :new, :create, :update], param: :uid do
    member do
      get :trigger_rules
      resources :alert_configuration_domain_users, only: [:index]
      resources :alert_configuration_tags, only: [:index]
    end
  end
  resources :triggered_alerts, only: [:index, :show], param: :uid

  resources :domains, only: [:create, :update, :new], param: :uid do
    resources :page_urls, only: [:update], param: :uid do
      collection do
        post '/create_or_update' => 'page_urls#create_or_update'
      end
    end
    resources :non_third_party_url_patterns, only: [:create, :destroy], param: :uid
  end
  put '/update_current_domain/:uid' => 'domains#update_current_domain', as: :update_current_domain

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

  get '/tag_management' => 'tags#tag_manager', as: :tag_manager
  resources :tags, param: :uid do
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
    resources :slack_notification_subscribers, only: [:create, :destroy], param: :uid
    resources :tag_allowed_performance_audit_third_party_urls, only: [:create, :destroy], param: :uid
    resources :tag_preferences, only: [:edit, :update], param: :uid
    resources :additional_tags_to_inject_during_audit, only: [:create, :destroy], param: :uid
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
      get '/test_run_for_audit/:uid' => 'test_runs#show_for_audit', as: :test_run_for_audit
      resources :page_change_audits, only: :show, param: :uid
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
    resources :domains, only: [:index, :show], param: :uid
    resources :subscription_prices, only: [:index, :show, :new, :create], param: :uid
    resources :lambda_functions, controller: :executed_step_functions, only: [:index, :show], param: :uid
    resources :aws_event_bridge_rules, only: [:index, :show, :update]
    resources :flags, only: [:index, :show], param: :uid do
      resources :object_flags, param: :uid
    end
    resources :tag_identifying_data, param: :uid do
      resources :tag_identifying_data_domains, only: :create, param: :uid
    end
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
    resources :tags, only: :index, param: :uid do
      resources :tag_versions, only: :index, param: :uid do
        member do
          get :diff
          get :live_comparison
        end
      end
    end
  end

  # resources :stripe_billing_portal, only: :new
  resources :domain_payment_methods, only: [:new, :create]
  resources :subscription_plans, only: [:create, :edit, :update], param: :uid do
    member do
      patch :cancel, param: :uid
    end
    collection do
      get :select
    end
  end
  resources :credit_wallets, only: [], param: :uid do
    resources :credit_wallet_transactions, only: :index
  end

  post '/api/stripe_webhook_receiver' => 'stripe_webhook_receiver#receive'
  post '/api/lambda_event_receiver/success' => 'lambda_event_receiver#success'

  get '/settings' => 'settings#global_settings'
  get '/settings/tag_management' => 'settings#tag_management'
  get '/settings/billing' => 'settings#billing'
  resources :url_crawls, only: [:index, :show, :create], param: :uid
  get '/settings/integrations/slack/oauth/redirect' => 'slack_settings#oauth_redirect'

  namespace :charts do
    resources :tags, only: [:index, :show], param: :uid
    resources :uptime_checks, only: [:index, :show], param: :uid
  end

  # get '/charts/domain/:domain_uid' => 'charts#tags', as: :domain_tags_chart
  # get '/charts/tag/:tag_uid' => 'charts#tag', as: :tag_chart
  # get '/charts/uptime/:domain_uid' => 'charts#tag_uptime', as: :tags_uptime_chart
  get '/charts/admin_audit_performance' => 'charts#admin_audit_performance', as: :admin_audit_performance_chart
  get '/charts/admin_lambda_functions' => 'charts#admin_executed_step_functions', as: :admin_executed_step_functions_chart
end

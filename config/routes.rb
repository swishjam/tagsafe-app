Rails.application.routes.draw do
  root 'welcome#index'
  post '/learn_more' => 'welcome#learn_more'

  require 'resque/server'
  mount Resque::Server.new, at: '/queue'

  # TODO: make my routes more Rails-y
  get '/login' => 'sessions#new'
  post '/login' => 'sessions#create'
  get '/logout' => 'sessions#destroy', as: :logout

  get '/demo' => 'demo#index'

  resources :registrations, only: [:new, :create]
  resources :organizations, only: [:new, :create]
  put '/update_current_organization/:uid' => 'organizations#update_current_organization', as: :update_current_organization
  
  resources :organization_users, only: [:destroy]
  resources :user_invites, only: [:new, :create]
  get '/user_invites/:token/accept' => 'user_invites#accept', as: :accept_invite
  post '/user_invites/:token/redeem' => 'user_invites#redeem', as: :redeem_invite

  get '/change_log' => 'tag_versions#index'
  get '/uptime' => 'tag_checks#index'
  get '/performance' => 'performance#index'

  resources :domains, only: [:create, :update, :new] do
    member do
      patch :crawl
    end
    resources :page_urls, only: [:update] do
      collection do
        post '/create_or_update' => 'page_urls#create_or_update'
      end
    end

    resources :url_crawls, only: [:index, :show] do
      member do
        get :executed_lambda_function
      end
    end
    resources :non_third_party_url_patterns, only: [:create, :destroy]
  end
  put '/update_current_domain/:uid' => 'domains#update_current_domain', as: :update_current_domain

  resources :functional_tests do
    member do
      post :validate
    end
  end

  resources :tags do
    member do
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
        get :begin_audit
        post :run_audit
        get :content
        get :git_diff
        get :js
        get '/js.js' => 'tag_versions#js'
        get :tagsafe_instrumented_js
        get '/tagsafe_instrumented_js.js' => 'tag_versions#tagsafe_instrumented_js'
      end
      resources :audits, only: [:show, :index] do
        member do
          get :performance_audit
          get :functional_tests
          get :page_change_audit
          get :waterfall
          get :git_diff
          get :cloudwatch_logs
          post :make_primary
          # get :html_snapshot_diff
        end
        resources :individual_performance_audits, only: :index
        resources :test_runs, only: [:index, :show]
        resources :page_change_audits, only: :show do
          resources :html_snapshots, only: [] do
            member do
              get :screenshot
            end
          end
        end
        resources :performance_audit_logs, only: :index
        resources :executed_lambda_functions, only: :index
        resources :page_load_resources, only: :index
        get '/waterfall' => 'page_load_resources#for_audit'
      end
    end
  end

  get '/admin' => redirect('/admin/performance')
  namespace :admin do
    get '/performance' => 'performance#index'
    resources :flags, only: [:index, :show] do
      resources :object_flags
    end
    resources :tag_images do
      member do
        post :apply_to_tags
      end
      collection do
        post :apply_all_to_tags
      end
      resources :tag_image_domain_lookup_patterns, only: [:create, :destroy]
    end
  end

  namespace :server_loadable_partials do
    resources :tags, only: :index do
      resources :tag_versions, only: :index do
        member do
          get :diff
        end
      end
    end
  end

  get '/settings/tag_management' => 'settings#tag_management'
  get '/settings/audit_settings' => 'settings#audit_settings'
  get '/settings/integrations/slack/oauth/redirect' => 'slack_settings#oauth_redirect'

  get '/charts/domain/:domain_id' => 'charts#tags', as: :domain_tags_chart
  get '/charts/tag/:tag_id' => 'charts#tag', as: :tag_chart
  get '/charts/uptime/:domain_id' => 'charts#tag_uptime', as: :tags_uptime_chart
  get '/charts/admin_audit_performance' => 'charts#admin_audit_performance', as: :admin_audit_performance_chart
end

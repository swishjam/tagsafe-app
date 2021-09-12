Rails.application.routes.draw do
  root 'welcome#index'

  require 'resque/server'
  mount Resque::Server.new, at: '/queue'

  # TODO: make my routes more Rails-y
  get '/login' => 'sessions#new'
  post '/login' => 'sessions#create'
  get '/logout' => 'sessions#destroy'

  get '/demo' => 'demo#index'

  resources :registrations, only: [:new, :create]
  resources :organizations, only: [:new, :create]
  
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
    resources :url_crawls, only: [:index, :show]
    resources :urls_to_crawl, only: [:create, :destroy]
    resources :non_third_party_url_patterns, only: [:create, :destroy]
  end
  post '/update_current_domain/:id' => 'domains#update_current_domain', as: :update_current_domain

  resources :tags do
    get '/general' => 'tags#edit' 
    get '/preferences' => 'tags#preferences'
    get '/notification_settings' => 'tags#notification_settings'

    resources :slack_notification_subscribers, only: [:create, :destroy]
    resources :tag_allowed_performance_audit_third_party_urls, only: [:create, :destroy]
    # resources :performance_audit_preferences, only: :update
    resources :tag_preferences, only: [:edit, :update]
    resources :tag_versions, only: [:show, :index] do
      member do
        post :run_audit
        get :content
        get :diff
        get :js
        get '/js.js' => 'tag_versions#js'
      end
      resources :audits, only: [:index, :show] do
        member do
          post :make_primary  
        end
        resources :individual_performance_audits, only: [:index]
        resources :performance_audit_logs, only: [:index]
      end
    end
  end

  namespace :admin do
    get '/performance' => 'performance#index'
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
  get '/settings/tag_settings' => 'settings#tag_settings'
  get '/settings/integrations/slack/oauth/redirect' => 'slack_settings#oauth_redirect'

  namespace :api do
    post '/tags/:id/toggle_active' => 'tags#toggle_active'
    post '/tags/:id/toggle_lighthouse' => 'tags#toggle_lighthouse'

    post '/notification_preferences/:tag_id/toggle_tag_version_notification' => 'notification_preferences#toggle_tag_version_notification'
    post '/notification_preferences/:tag_id/toggle_audit_complete_notification' => 'notification_preferences#toggle_audit_complete_notification'
    post '/notification_preferences/:tag_id/toggle_lighthouse_audit_exceeded_threshold_notification' => 'notification_preferences#toggle_lighthouse_audit_exceeded_threshold_notification'
  
    post 'geppetto_receiver/url_crawl_complete' => 'geppetto_receiver#url_crawl_complete'
    post 'geppetto_receiver/performance_audit_complete' => 'geppetto_receiver#performance_audit_complete'
  end

  
  get '/charts/domain/:domain_id' => 'charts#tags', as: :domain_tags_chart
  get '/charts/tag/:tag_id' => 'charts#tag', as: :tag_chart
  get '/charts/uptime/:domain_id' => 'charts#tag_uptime', as: :tags_uptime_chart
  get '/charts/admin_audit_performance' => 'charts#admin_audit_performance', as: :admin_audit_performance_chart
end

Rails.application.routes.draw do
  root 'welcome#index'

  require 'resque/server'
  mount Resque::Server.new, at: '/queue'

  # TODO: make my routes more Rails-y
  get '/login' => 'sessions#new'
  post '/login' => 'sessions#create'
  get '/logout' => 'sessions#destroy'

  resources :registrations, only: [:new, :create]
  
  resources :organization_users, only: [:destroy]
  resources :user_invites, only: [:new, :create]
  get '/user_invites/:token/accept' => 'user_invites#accept', as: :accept_invite
  post '/user_invites/:token/redeem' => 'user_invites#redeem', as: :redeem_invite

  resources :scripts, only: :index
  get '/change_log' => 'script_changes#index'

  post '/update_current_domain/:id' => 'domains#update_current_domain', as: :update_current_domain

  resources :script_subscribers, only: [:index, :show, :edit, :update] do
    resources :script_subscriber_allowed_performance_audit_tags, only: [:create, :destroy]
    resources :script_changes, only: [:show, :index] do
      member do
        post :run_audit
        get :content
      end
      resources :audits, only: [:index, :show] do
        member do
          post :make_primary  
        end
        resources :performance_audit_logs, only: [:index]
      end
    end
  end
  resources :tests
  resources :test_subscribers do
    collection do
      post '/enqueue_test_suite_for_script/:domain_id/:script_id' => 'test_subscribers#enqueue_test_suite_for_script', as: :enqueue_test_suite_for_script
    end
  end

  get '/notification_preferences' => 'notification_preferences#index'

  namespace :admin do
    resources :script_images do
      member do
        post :apply_to_scripts
      end
      collection do
        post :apply_all_to_scripts
      end
      resources :script_image_domain_lookup_patterns, only: [:create, :destroy]
    end
  end

  namespace :api do
    post '/test_subscriptions/:id/toggle' => 'test_subscriptions#toggle'

    post '/script_subscribers/:id/toggle_active' => 'script_subscribers#toggle_active'
    post '/script_subscribers/:id/toggle_lighthouse' => 'script_subscribers#toggle_lighthouse'

    post '/notification_preferences/:script_subscriber_id/toggle_script_change_notification' => 'notification_preferences#toggle_script_change_notification'
    post '/notification_preferences/:script_subscriber_id/toggle_audit_complete_notification' => 'notification_preferences#toggle_audit_complete_notification'
    post '/notification_preferences/:script_subscriber_id/toggle_lighthouse_audit_exceeded_threshold_notification' => 'notification_preferences#toggle_lighthouse_audit_exceeded_threshold_notification'
    post '/notification_preferences/:script_subscriber_id/toggle_test_failed_notification' => 'notification_preferences#toggle_test_failed_notification'
  
    post 'geppetto_receiver/domain_scan_complete' => 'geppetto_receiver#domain_scan_complete'
    post 'geppetto_receiver/standalone_test_complete' => 'geppetto_receiver#standalone_test_complete'
    post 'geppetto_receiver/test_group_complete' => 'geppetto_receiver#test_group_complete'
    post 'geppetto_receiver/performance_audit_complete' => 'geppetto_receiver#performance_audit_complete'
  end

  
  get '/charts/domain/:domain_id' => 'charts#script_subscribers', as: :domain_script_subscribers_chart
  get '/charts/script_subscriber/:script_subscriber_id' => 'charts#script_subscriber', as: :script_subscriber_chart
end

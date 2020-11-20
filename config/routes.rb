Rails.application.routes.draw do
  root 'welcome#index'

  require 'resque/server'
  mount Resque::Server.new, at: '/queue'

  # TODO: make my routes more Rails-y
  get '/login' => 'sessions#new'
  post '/login' => 'sessions#create'
  get '/logout' => 'sessions#destroy'

  resources :scripts, only: :index

  resources :domains do
    member do
      get '/test_subscriptions' => 'test_subscribers#domain_tests' # move this to test_subscriptions routes
      get '/run_standalone_test' => 'tests#run_standalone_test'
      post '/post_standalone_test' => 'tests#post_standalone_test'
      post '/update_current_domain' => 'domains#update_current_domain'
    end
  end

  resources :script_subscribers, only: [:index, :show, :edit, :update] do
    resources :script_changes, only: [:show] do
      member do
        post :run_audit
      end
      resources :audits, only: [:index, :show] do
        member do
          post :make_primary  
        end
      end
      resources :lighthouse_audits, only: [:show]
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
    resources :script_domain_images
    resources :script_images
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
    post 'geppetto_receiver/lighthouse_audit_complete' => 'geppetto_receiver#lighthouse_audit_complete'
  end

  
  get '/charts/domain/:domain_id/script_changes' => 'charts#script_changes', as: :script_changes_chart
  get '/charts/domain/:domain_id/script_changes/:script_change_id' => 'charts#script_change', as: :script_change_chart
end

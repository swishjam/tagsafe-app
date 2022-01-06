Rails.logger.info "Initializing HireFire config..."
HireFire::Resource.configure do |config|
  config.dyno(:default_queue) do
    HireFire::Macro::Resque.queue(:default)
  end
  
  config.dyno(:tag_checker_queue) do
    HireFire::Macro::Resque.queue(:tag_checker_queue)
  end
  
  config.dyno(:performance_audit_runner_queue) do
    HireFire::Macro::Resque.queue(:performance_audit_runner_queue)
  end
  
  config.dyno(:functional_tests_queue) do
    HireFire::Macro::Resque.queue(:functional_tests_queue)
  end
  
  config.dyno(:resque_scheduler) do
    HireFire::Macro::Resque.queue(:resque_scheduler)
  end
end
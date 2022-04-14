Rails.logger.info "Initializing HireFire config..."
HireFire::Resource.configure do |config|
  config.dyno(:worker) do
    HireFire::Macro::Resque.queue(:critical, :normal, :low, :default)
  end

  config.dyno(:lambda_results) do
    HireFire::Macro::Resque.queue(:lambda_results)
  end

  config.dyno(:scheduled_audit_queue) do
    HireFire::Macro::Resque.queue(:scheduled_audit_queue)
  end
  
  config.dyno(:resque_scheduler) do
    HireFire::Macro::Resque.queue(:resque_scheduler)
  end
end
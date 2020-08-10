require 'active_scheduler'

Resque.redis = 'localhost:6379'

Resque.logger = Logger.new(STDOUT)
Resque.logger.level = Logger::INFO
# Resque.logger.formatter = Resque::VerboseFormatter.new

yaml_schedule    = YAML.load_file(Rails.root.join('config', 'cron-schedule.yml'))
wrapped_schedule = ActiveScheduler::ResqueWrapper.wrap yaml_schedule
Resque.schedule  = wrapped_schedule
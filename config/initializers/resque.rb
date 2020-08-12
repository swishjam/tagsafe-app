require 'active_scheduler'
require 'resque/server'

Resque::Server.use(Rack::Auth::Basic) do |user, password|
  password === ENV['RESQUE_PASSWORD']
end

Resque.redis = ENV['REDIS_URL'] || 'localhost:6379'

Resque.logger = Logger.new(STDOUT)
Resque.logger.level = Logger::INFO

yaml_schedule    = YAML.load_file(Rails.root.join('config', 'cron-schedule.yml'))
wrapped_schedule = ActiveScheduler::ResqueWrapper.wrap yaml_schedule
Resque.schedule  = wrapped_schedule
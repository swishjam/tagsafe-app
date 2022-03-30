require 'active_scheduler'
require 'resque/server'
Dir[Rails.root.join('app', 'jobs', 'schedule', 'tag_check_jobs', '*.rb')].each { |file| require file }
Dir[Rails.root.join('app', 'jobs', 'schedule', 'scheduled_audit_jobs', '*.rb')].each { |file| require file }

Resque::Server.use(Rack::Auth::Basic) do |user, password|
  password === ENV['RESQUE_PASSWORD']
end

Resque.redis = { url: ENV['REDIS_URL'] || 'redis://localhost:6379', ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE }}

Resque.logger = Logger.new(STDOUT)
Resque.logger.level = Logger::INFO

yaml_schedule    = YAML.load_file(Rails.root.join('config', 'cron-schedule.yml'))
wrapped_schedule = ActiveScheduler::ResqueWrapper.wrap yaml_schedule
Resque.schedule  = wrapped_schedule
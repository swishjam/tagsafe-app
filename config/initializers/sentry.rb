return if Rails.env.test?

Sentry.init do |config|
  config.dsn = 'https://8a99d2da90d1429097ea83c9396ae25c@o1079626.ingest.sentry.io/6084628'
  config.breadcrumbs_logger = [:active_support_logger, :http_logger]

  # Set tracesSampleRate to 1.0 to capture 100%
  # of transactions for performance monitoring.
  # We recommend adjusting this value in production
  config.traces_sample_rate = (ENV['SENTRY_SAMPLE_RATE'] || Rails.env.development? ? 1.0 : 0.5).to_i
  # or
  # config.traces_sampler = lambda do |context|
  #   true
  # end
end
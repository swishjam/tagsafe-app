module MandatoryDataEnforcer
  class EnvironmentalVariables
    REQUIRED_ENVS = %w[
      AWS_ACCESS_KEY_ID
      AWS_SECRET_ACCESS_KEY
      SENDGRID_API_KEY
      SENDGRID_USERNAME
      SENDGRID_PASSWORD
      CLOUDFRONT_HOSTNAME
      ASSET_CDN_DOMAIN
      ASSET_S3_BUCKET
      TAGSAFE_INSTRUMENTATION_CLOUDFRONT_DISTRIBUTION_ID
      REDIS_URL
      TAGSAFE_JS_REPORTING_URL
    ]

    def self.validate!
      envs = REQUIRED_ENVS.find_all{ |env| ENV.fetch(env) == nil }
      return if envs.empty?
      raise "Missing required ENVs: #{envs.join(', ')}"
    end
  end
end
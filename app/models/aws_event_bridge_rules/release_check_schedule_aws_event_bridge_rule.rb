class ReleaseCheckScheduleAwsEventBridgeRule < AwsEventBridgeRule
  RELEASE_CHECK_AWS_REGION = 'us-east-1'.freeze

  def self.for_interval(minute_interval)
    interval_name = minute_interval.to_i >= 60 ? "#{minute_interval / 60}-hour" : "#{minute_interval}-minute"
    begin
      find_by!(region: RELEASE_CHECK_AWS_REGION, name: "#{ENV['LAMBDA_ENVIRONMENT'] || Rails.env}-#{interval_name}-release-check-schedule")
    rescue ActiveRecord::RecordNotFound => e
      raise ActiveRecord::RecordNotFound, "ReleaseCheckScheduleAwsEventBridgeRule with a name of `#{ENV['LAMBDA_ENVIRONMENT'] || Rails.env}-#{interval_name}-release-check-schedule` does not exist in Tagsafe."
    end
  end
end
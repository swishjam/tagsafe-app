class UptimeCheckScheduleAwsEventBridgeRule < AwsEventBridgeRule
  def self.for_uptime_region(uptime_region)
    find_by!(region: uptime_region.aws_region_name, name: "#{ENV['LAMBDA_ENVIRONMENT'] || Rails.env}-1-minute-uptime-check-schedule")
  end
end
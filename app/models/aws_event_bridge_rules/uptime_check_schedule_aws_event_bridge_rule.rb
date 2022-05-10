class UptimeCheckScheduleAwsEventBridgeRule < AwsEventBridgeRule
  def self.for_uptime_region!(uptime_region)
    name = "#{ENV['LAMBDA_ENVIRONMENT'] || Rails.env}-1-minute-uptime-check-schedule"
    begin
      find_by!(region: uptime_region.aws_region_name, name: name)
    rescue ActiveRecord::RecordNotFound => e
      raise ActiveRecord::RecordNotFound, "UptimeCheckScheduleAwsEventBridgeRule with a name of `#{name}` does not exist in Tagsafe."
    end
  end
end
class UptimeCheckScheduleAwsEventBridgeRule < AwsEventBridgeRule
  def self.for_uptime_region!(uptime_region)
    for_region_name!(uptime_region.aws_region_name)
  end

  def self.for_region_name!(region_name)
    name = "#{ENV['LAMBDA_ENVIRONMENT'] || Rails.env}-uptime-check-schedule"
    begin
      find_by!(region: region_name, name: name)
    rescue ActiveRecord::RecordNotFound => e
      raise ActiveRecord::RecordNotFound, "UptimeCheckScheduleAwsEventBridgeRule with a name of `#{name}` for the #{region_name} region does not exist in Tagsafe."
    end
  end
end
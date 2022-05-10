class UptimeRegionToCheck < ApplicationRecord
  self.table_name = :uptime_regions_to_check
  belongs_to :tag
  belongs_to :uptime_region

  after_create { enable_aws_event_bridge_rules_for_region_if_necessary! }
  before_destroy { disable_aws_event_bridge_rules_if_no_tags_monitoring_uptime_for_region! }


  def disable_aws_event_bridge_rules_if_no_tags_monitoring_uptime_for_region!
    return if self.class.where(uptime_region: uptime_region).any?
    ReleaseCheckScheduleAwsEventBridgeRule.for_uptime_region!(uptime_region).disable!
  end

  def enable_aws_event_bridge_rules_for_region_if_necessary!
    return false if tag.release_monitoring_disabled?
    UptimeCheckScheduleAwsEventBridgeRule.for_uptime_region!(uptime_region).enable!
  end
end
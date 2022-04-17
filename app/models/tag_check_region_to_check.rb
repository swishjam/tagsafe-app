class TagCheckRegionToCheck < ApplicationRecord
  self.table_name = :tag_check_regions_to_check
  belongs_to :tag
  belongs_to :tag_check_region

  before_destroy :ensure_not_destroying_us_east_1

  after_create { tag_check_region.enable_aws_event_bridge_rules_for_tag_check_region_if_necessary!(tag.tag_preferences.tag_check_minute_interval) unless tag.release_monitoring_disabled? }
  after_destroy { tag_check_region.disable_aws_event_bridge_rules_if_no_tag_checks_enabled_for_interval!(tag.tag_preferences.tag_check_minute_interval) unless tag.release_monitoring_disabled? }

  def user_can_destroy?
    tag_check_region != TagCheckRegion.US_EAST_1
  end

  private

  def ensure_not_destroying_us_east_1
    unless user_can_destroy?
      errors.add(:base, "Cannot remove the #{tag_check_region.location} region, as it is the region used for release monitoring. Turn off Uptime Monitoring if you'd no longer to like to monitor the tag's uptime at all.")
    end
  end
end
class TagCheckRegionToCheck < ApplicationRecord
  self.table_name = :tag_check_regions_to_check
  belongs_to :tag
  belongs_to :tag_check_region

  before_destroy :ensure_not_destroying_us_east_1

  after_create { LambdaCronJobDataStore::TagCheckIntervals.new(tag).add_current_tag_check_interval_configuration_to_tag_check_region(tag_check_region) }
  after_destroy { LambdaCronJobDataStore::TagCheckIntervals.new(tag).remove_current_tag_check_interval_configuration_from_tag_check_region(tag_check_region) }

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
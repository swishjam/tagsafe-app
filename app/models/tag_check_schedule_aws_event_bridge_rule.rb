class TagCheckScheduleAwsEventBridgeRule < ApplicationRecord
  belongs_to :tag_check_region
  validates_uniqueness_of :associated_tag_check_minute_interval, scope: :tag_check_region_id
  validates :associated_tag_check_minute_interval, inclusion: { in: %w[1 15 30 60 180 360 720 1440] }

  scope :enabled, -> { where(enabled: true) }
  scope :disabled, -> { where(enabled: false) }
  scope :by_region_name, -> (aws_region_name) { joins(:tag_check_region).where(tag_check_region: { aws_name: aws_region_name }) }

  def self.for_interval(interval)
    find_by(associated_tag_check_minute_interval: interval.to_s)
  end
  
  def enable!
    return true unless disabled?
    TagsafeAws::EventBridge.enable_rule(name, region: tag_check_region.aws_region_name)
    update!(enabled: true)
  end
  alias enable_if_necessary enable!

  def disable!
    return true unless enabled?
    TagsafeAws::EventBridge.disable_rule(name, region: tag_check_region.aws_region_name)
    update!(enabled: false)
  end

  def enabled?
    enabled
  end

  def disabled?
    !enabled
  end

  def tags_being_checked_for_interval
    Tag.where_tag_check_interval(associated_tag_check_minute_interval.to_i)
  end
end
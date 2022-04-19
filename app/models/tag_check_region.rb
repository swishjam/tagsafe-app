class TagCheckRegion < ApplicationRecord  
  has_many :tag_checks
  has_many :tag_check_schedule_aws_event_bridge_rules
  has_many :tag_check_regions_to_check, class_name: TagCheckRegionToCheck.to_s, dependent: :destroy
  has_many :tags, through: :tag_check_regions_to_check

  scope :not_enabled_on_tag, -> (tag) { where.not(id: tag.tag_check_regions.collect(&:id)) }
  scope :selectable, -> { where(aws_name: %w[us-east-1 us-east-2 us-west-1 us-west-2 eu-central-1 eu-west-1 eu-west-2 eu-west-3 ap-northeast-1 ap-south-1 ap-southeast-1 ap-southeast-2 sa-east-1 ca-central-1]) }

  validates_uniqueness_of :aws_name

  def self.REGION_NAMES
    @region_names ||= all.collect(&:aws_region_name)
  end

  def self.US_EAST_1
    @aws_east_1 ||= find_by!(aws_name: 'us-east-1')
  end

  def aws_region_name
    aws_name
  end

  def tags_being_checked_for_interval(interval)
    tags.where_tag_check_interval(interval.to_i)
  end

  def enable_aws_event_bridge_rules_for_tag_check_region_if_necessary!(interval)
    event_bridge_rule = tag_check_schedule_aws_event_bridge_rules.for_interval(interval)
    if event_bridge_rule.nil?
      raise TagsafeAwsEventBridgeRuleError::DoesNotExist, <<~ERR
        Cannot enable AWS Event Bridge Rule, TagCheckRegion #{aws_region_name} does not have a 
        TagCheckScheduleAwsEventBridgeRule with an interval of #{interval}.
      ERR
    else
      event_bridge_rule.enable_if_necessary
    end
  end

  def disable_aws_event_bridge_rules_if_no_tag_checks_enabled_for_interval!(interval)
    unless tags_being_checked_for_interval(interval).any?
      tag_check_schedule_aws_event_bridge_rules.for_interval(interval).disable!
    end
  end
end
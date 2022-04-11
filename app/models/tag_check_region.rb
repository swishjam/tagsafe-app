class TagCheckRegion < ApplicationRecord  
  has_many :tag_checks
  has_many :tag_check_schedule_aws_event_bridge_rules

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
end
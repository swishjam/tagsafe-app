class UptimeRegion < ApplicationRecord  
  has_many :uptime_check_batches
  has_many :uptime_checks
  has_many :uptime_regions_to_check, class_name: UptimeRegionToCheck.to_s, dependent: :destroy
  has_many :tags, through: :uptime_regions_to_check

  scope :not_enabled_on_tag, -> (tag) { where.not(id: tag.uptime_regions.collect(&:id)) }
  scope :selectable, -> { where(aws_name: UptimeRegion::SELECTABLE_AWS_REGION_NAMES) }

  SELECTABLE_AWS_REGION_NAMES = %w[
    us-east-1 us-east-2 us-west-1 us-west-2 eu-central-1 eu-west-1 eu-west-2 eu-west-3 
    ap-northeast-1 ap-south-1 ap-southeast-1 ap-southeast-2 sa-east-1 ca-central-1
  ]

  validates_uniqueness_of :aws_name

  def self.REGION_NAMES
    @region_names ||= all.collect(&:aws_region_name)
  end

  def self.US_EAST_1
    @aws_east_1 ||= self.FOR_AWS_REGION('us-east-1')
  end

  def self.FOR_AWS_REGION(region_name)
    find_by(aws_name: region_name)
  end

  def aws_region_name
    aws_name
  end

  def tags_being_checked_for_interval(interval)
    tags.where_release_check_interval(interval.to_i)
  end
end
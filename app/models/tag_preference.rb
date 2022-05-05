class TagPreference < ApplicationRecord
  acts_as_paranoid
  
  belongs_to :tag
  
  after_update :check_to_sync_aws_event_bridge_rules_if_necessary
  after_create { enable_aws_event_bridge_rules_for_each_tag_check_region_if_necessary! unless release_monitoring_disabled? }
  before_destroy { disable_aws_event_bridge_rules_if_no_tag_checks_enabled_for_interval!(tag_check_minute_interval) unless tag.nil? }

  # validate :has_payment_method_on_file_when_necessary
  validates :tag_check_minute_interval, inclusion: { in: [nil, 1, 15, 30, 60, 180, 360, 720, 1_440] }
  validates :scheduled_audit_minute_interval, inclusion: { in: [nil, 5, 15, 30, 60, 180, 360, 720, 1_440] }

  TAG_CHECK_INTERVALS = [
    { name: '1 minute', value: 1 },
    { name: '15 minutes', value: 15 },
    { name: '30 minutes', value: 30 },
    { name: '1 hour', value: 60 },
    { name: '3 hours', value: 180 },
    { name: '6 hours', value: 360 },
    { name: '12 hours', value: 720 },
    { name: '1 day', value: 1_440 },
  ].freeze

  SCHEDULED_AUDIT_INTERVALS = [
    { name: '5 minutes', value: 5 },
    { name: '15 minutes', value: 15 },
    { name: '30 minutes', value: 30 },
    { name: '1 hour', value: 60 },
    { name: '3 hours', value: 180 },
    { name: '6 hours', value: 360 },
    { name: '12 hours', value: 720 },
    { name: '1 day', value: 1_440 },
  ].freeze

  def self.SUPPORTED_TAG_CHECK_INTERVALS
    self::TAG_CHECK_INTERVALS.collect{ |opt| opt[:value] }
  end

  def self.SUPPORTED_SCHEDULED_AUDIT_INTERVALS
    self::SCHEDULED_AUDIT_INTERVALS.collect{ |opt| opt[:value] }
  end

  def scheduled_audits_enabled?
    scheduled_audit_minute_interval.present?
  end

  def scheduled_audits_disabled?
    !scheduled_audits_enabled?
  end

  def release_monitoring_enabled?
    tag_check_minute_interval.present?
  end

  def release_monitoring_disabled?
    !release_monitoring_enabled?
  end

  private

  def check_to_sync_aws_event_bridge_rules_if_necessary
    if saved_changes['tag_check_minute_interval']
      previous_tag_check_minute_interval = saved_changes['tag_check_minute_interval'][0]
      enable_aws_event_bridge_rules_for_each_tag_check_region_if_necessary!
      disable_aws_event_bridge_rules_if_no_tag_checks_enabled_for_interval!(previous_tag_check_minute_interval)
    end
  end

  def disable_aws_event_bridge_rules_if_no_tag_checks_enabled_for_interval!(interval)
    # check each tag_check_region that was enabled for this tag
    # if there are no more tag_checks being run on the interval for the region then disable the rule.
    return if interval.nil?
    tag.tag_check_regions.each do |tag_check_region|
      tag_check_region.disable_aws_event_bridge_rules_if_no_tag_checks_enabled_for_interval!(interval)
    end
  end

  def enable_aws_event_bridge_rules_for_each_tag_check_region_if_necessary!
    return false if release_monitoring_disabled?
    tag.tag_check_regions.each do |tag_check_region|
      tag_check_region.enable_aws_event_bridge_rules_for_tag_check_region_if_necessary!(tag_check_minute_interval)
    end
  end
end
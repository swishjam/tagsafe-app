class TagPreference < ApplicationRecord
  acts_as_paranoid
  
  belongs_to :tag
  
  after_update :check_to_sync_aws_event_bridge_rules_if_necessary
  after_create { enable_aws_event_bridge_rules_for_release_check_interval_if_necessary! unless release_monitoring_disabled? }
  before_destroy { disable_aws_event_bridge_rules_if_no_release_checks_enabled_for_interval(release_check_minute_interval) unless tag.nil? }

  # validate :has_payment_method_on_file_when_necessary
  validates :release_check_minute_interval, inclusion: { in: [0, 1, 15, 30, 60, 180, 360, 720, 1_440] }
  validates :scheduled_audit_minute_interval, inclusion: { in: [0, 5, 15, 30, 60, 180, 360, 720, 1_440] }

  RELEASE_CHECK_INTERVALS = [
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

  def self.SUPPORTED_RELEASE_CHECK_INTERVALS
    self::RELEASE_CHECK_INTERVALS.collect{ |opt| opt[:value] }
  end

  def self.SUPPORTED_SCHEDULED_AUDIT_INTERVALS
    self::SCHEDULED_AUDIT_INTERVALS.collect{ |opt| opt[:value] }
  end

  def scheduled_audit_interval_in_words
    Util.integer_to_interval_in_words(scheduled_audit_minute_interval)
  end

  def release_monitoring_interval_in_words
    Util.integer_to_interval_in_words(release_check_minute_interval)
  end
  alias release_check_interval_in_words release_monitoring_interval_in_words

  def scheduled_audits_enabled?
    scheduled_audit_minute_interval.positive?
  end

  def scheduled_audits_disabled?
    !scheduled_audits_enabled?
  end

  def release_monitoring_enabled?
    release_check_minute_interval.positive?
  end

  def release_monitoring_disabled?
    !release_monitoring_enabled?
  end

  private

  def check_to_sync_aws_event_bridge_rules_if_necessary
    if saved_changes['release_check_minute_interval']
      previous_release_check_minute_interval = saved_changes['release_check_minute_interval'][0]
      enable_aws_event_bridge_rules_for_release_check_interval_if_necessary!
      disable_aws_event_bridge_rules_if_no_release_checks_enabled_for_interval(previous_release_check_minute_interval)
    end
  end

  def disable_aws_event_bridge_rules_if_no_release_checks_enabled_for_interval(interval)
    return if interval.zero?
    return if TagPreference.where(release_check_minute_interval: interval).any?
    ReleaseCheckScheduleAwsEventBridgeRule.for_interval(interval).disable!
  end

  def enable_aws_event_bridge_rules_for_release_check_interval_if_necessary!
    return false if release_monitoring_disabled?
    ReleaseCheckScheduleAwsEventBridgeRule.for_interval(release_check_minute_interval).enable!
  end
end
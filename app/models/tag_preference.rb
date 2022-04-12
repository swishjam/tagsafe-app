class TagPreference < ApplicationRecord
  acts_as_paranoid
  
  belongs_to :tag
  
  after_update :check_to_update_release_monitoring_preferences
  after_create { AfterTagCheckIntervalChangeJob.perform_later(tag_id, previous_interval: nil, new_interval: tag_check_minute_interval) unless release_monitoring_disabled? }
  before_destroy { AfterTagCheckIntervalChangeJob.perform_later(tag_id, previous_interval: tag_check_minute_interval, new_interval: nil) }

  validate :has_payment_method_on_file_when_necessary
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

  def has_payment_method_on_file_when_necessary
    if !tag.domain.has_payment_method_on_file? && (release_monitoring_enabled? || scheduled_audits_enabled?)
      errors.add(:base, "Must have a payment method on file in order to enable automated features (release monitoring, scheduled audits, uptime measurement).")
    end
  end

  def check_to_update_release_monitoring_preferences
    if saved_changes['tag_check_minute_interval']
      AfterTagCheckIntervalChangeJob.perform_later(tag_id, previous_interval: saved_changes['tag_check_minute_interval'][0], new_interval: tag_check_minute_interval)
    end
  end
end
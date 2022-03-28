class TagPreference < ApplicationRecord
  acts_as_paranoid
  
  belongs_to :tag
  
  after_update :check_to_run_audit

  validate :tag_check_minute_interval_is_supported_value
  validate :scheduled_audit_minute_interval_is_supported_value

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

  private

  def tag_check_minute_interval_is_supported_value
    if tag_check_minute_interval.present? && !TAG_CHECK_INTERVALS.map{ |opt| opt[:value] }.include?(tag_check_minute_interval)
      errors.add(:base, "Invalid tag check interval value.")
    end
  end

  def scheduled_audit_minute_interval_is_supported_value
    if scheduled_audit_minute_interval.present? && !SCHEDULED_AUDIT_INTERVALS.map{ |opt| opt[:value] }.include?(scheduled_audit_minute_interval)
      errors.add(:base, "Invalid scheduled audit interval value: #{scheduled_audit_minute_interval}.")
    end
  end

  def check_to_run_audit
    if column_changed_to('enabled', true)
      AfterTagShouldRunAuditActivationJob.perform_later(tag)
    end
  end
end
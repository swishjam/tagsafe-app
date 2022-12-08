class TagConfiguration < ApplicationRecord
  belongs_to :tag

  attribute :scheduled_audit_minute_interval, default: 0

  # validate :has_payment_method_on_file_when_necessary
  validates :release_check_minute_interval, inclusion: { in: [0, 1, 15, 30, 60, 180, 360, 720, 1_440] }
  validates :scheduled_audit_minute_interval, inclusion: { in: [0, 5, 15, 30, 60, 180, 360, 720, 1_440] }
  validates :load_type, inclusion: { in: %w[async defer synchronous] }
  validates :script_inject_event, inclusion: { in: %w[immediate load] }
  validates :script_inject_location, inclusion: { in: %w[head body] }

  scope :enabled, -> { where(enabled: true) }

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

  def enabled?
    enabled
  end

  def disabled?
    !enabled?
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
end
class AlertConfiguration < ApplicationRecord
  class << self
    attr_accessor :has_trigger_rules, 
                  :user_facing_alert_name,
                  :user_facing_alert_description
    
    def TYPES
      [
        PerformanceAuditExceededThresholdAlertConfiguration,
        FailedNetworkRequestAlertConfiguration,
        FunctionalTestSuiteFailedAlertConfiguration,
        NewTagAlertConfiguration,
        NewTagVersionAlertConfiguration,
        TagRemovedAlertConfiguration,
        SlowNetworkResponseAlertConfiguration
      ]
    end
  end
  uid_prefix 'alrt'
  self.has_trigger_rules = true

  belongs_to :container
  has_many :triggered_alerts, dependent: :destroy
  has_many :alert_configuration_container_users, dependent: :destroy
  has_many :container_users, through: :alert_configuration_container_users
  has_many :alert_configuration_tags, dependent: :destroy
  has_many :tags, through: :alert_configuration_tags
  accepts_nested_attributes_for :alert_configuration_container_users
  accepts_nested_attributes_for :alert_configuration_tags

  # should be set in subclass
  # serialize :trigger_rules, JSON

  validate :has_acceptable_trigger_rules_validation

  scope :active, -> { where(disabled: false) }
  scope :enabled, -> { active }
  scope :inactive, -> { where(disabled: true) }
  scope :disabled, -> { inactive }
  scope :enabled_for_all_tags, -> { where(enabled_for_all_tags: true) }
  scope :not_enabled_for_all_tags, -> { where(enabled_for_all_tags: false) }
  scope :by_klass, -> (klass) { where(type: klass.to_s) }

  def self.alert_email_klass
    "TagsafeEmail::#{self.to_s.gsub('AlertConfiguration', '')}Alert".constantize
  end

  def disabled?
    disabled
  end

  def enabled?
    !disabled?
  end

  def has_acceptable_trigger_rules_validation
    if self.class.has_trigger_rules && enabled? && !trigger_rules.valid?
      errors.add(:base, trigger_rules.invalid_error_message)
    end
  end

  def trigger_rules_description
    raise "AlertConfiguration subclass #{self.class.to_s} must implement the `trigger_rules_description` method."
  end

  def triggered_alert_description
    raise "AlertConfiguration subclass #{self.class.to_s} must implement the `triggered_alert_description` method."
  end
end
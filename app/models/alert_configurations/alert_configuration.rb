class AlertConfiguration < ApplicationRecord
  class << self
    attr_accessor :serializer_klass, 
                  :is_domain_level_alert, 
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
  self.is_domain_level_alert = false

  belongs_to :domain
  has_many :triggered_alerts, dependent: :destroy
  has_many :alert_configuration_domain_users, dependent: :destroy
  has_many :domain_users, through: :alert_configuration_domain_users
  has_many :alert_configuration_tags, dependent: :destroy
  has_many :tags, through: :alert_configuration_tags
  accepts_nested_attributes_for :alert_configuration_domain_users
  accepts_nested_attributes_for :alert_configuration_tags

  # should be set in subclass
  # serialize :trigger_rules, JSON

  validate :has_acceptable_trigger_rules_validation

  scope :enabled_for_all_tags, -> { where(enabled_for_all_tags: true) }
  scope :not_enabled_for_all_tags, -> { where(enabled_for_all_tags: false) }
  scope :by_klass, -> (klass) { where(type: klass.to_s) }

  def self.in_app_notification_partial_path
    file_name = self.to_s.gsub('AlertConfiguration', '').split(/(?=[A-Z])/).map{ |word| word.downcase! }.join('_')
    "/alert_configurations/in_app_notifications/#{file_name}"
  end

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
    if enabled? && !trigger_rules.valid?
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
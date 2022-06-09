class AlertConfiguration < ApplicationRecord
  class << self
    attr_accessor :serializer_klass, :is_domain_level_alert, :trigger_rule_fields, :user_facing_alert_name

    def TYPES
      [
        AuditCompletedAlertConfiguration,
        AuditExceededThresholdAlertConfiguration,
        FailedNetworkRequestAlertConfiguration,
        FunctionalTestFailedAlertConfiguration,
        NewTagAlertConfiguration,
        NewTagVersionAlertConfiguration,
        RemovedTagAlertConfiguration,
        SlowNetworkResponseAlertConfiguration
      ]
    end
  end
  uid_prefix 'alrt'
  self.is_domain_level_alert = false

  belongs_to :domain
  has_many :triggered_alerts
  has_many :alert_configuration_domain_users
  has_many :domain_users, through: :alert_configuration_domain_users
  has_many :alert_configuration_tags
  has_many :tags, through: :alert_configuration_tags
  accepts_nested_attributes_for :alert_configuration_domain_users
  accepts_nested_attributes_for :alert_configuration_tags

  # serialize :trigger_rules, JSON
  serialize :trigger_rules, self.serializer_klass || JSON

  validate :has_acceptable_trigger_rules_validation

  scope :enabled_for_all_tags, -> { where(enable_for_all_tags: true) }
  scope :not_enabled_for_all_tags, -> { where(enable_for_all_tags: false) }
  scope :by_klass, -> (klass) { where(type: klass.to_s) }

  def has_acceptable_trigger_rules_validation; true; end

  def trigger_rules_description
    raise "AlertConfiguration subclass #{self.class.to_s} must implement the `trigger_rules_description` method."
  end

  def triggered_alert_description
    raise "AlertConfiguration subclass #{self.class.to_s} must implement the `triggered_alert_description` method."
  end
end
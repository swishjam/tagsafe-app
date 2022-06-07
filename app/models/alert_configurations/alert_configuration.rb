class AlertConfiguration < ApplicationRecord
  class << self
    attr_accessor :is_domain_level_alert, :trigger_rule_fields, :user_facing_alert_name
  end
  self.is_domain_level_alert = false

  belongs_to :domain
  has_many :alert_configuration_domain_users
  has_many :users, through: :alert_configuration_domain_users
  has_many :alert_configuration_tags
  has_many :domain_users, through: :alert_configuration_users
  has_many :tags, through: :alert_configuration_tags

  serialize :trigger_rules

  validates :has_acceptable_trigger_rules_validation

  def has_acceptable_trigger_rules_validation; true; end
end
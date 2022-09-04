class AlertConfigurationDomainUser < ApplicationRecord
  belongs_to :alert_configuration
  belongs_to :domain_user

  validates_uniqueness_of :domain_user_id, scope: :alert_configuration_id
end
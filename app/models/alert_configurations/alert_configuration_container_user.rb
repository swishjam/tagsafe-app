class AlertConfigurationContainerUser < ApplicationRecord
  belongs_to :alert_configuration
  belongs_to :container_user

  validates_uniqueness_of :container_user_id, scope: :alert_configuration_id
end
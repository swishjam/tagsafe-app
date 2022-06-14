class AlertConfigurationTag < ApplicationRecord
  belongs_to :alert_configuration
  belongs_to :tag

  validates_uniqueness_of :tag_id, scope: :alert_configuration_id
end
class TriggeredAlertDomainUser < ApplicationRecord
  belongs_to :triggered_alert
  belongs_to :domain_user
end
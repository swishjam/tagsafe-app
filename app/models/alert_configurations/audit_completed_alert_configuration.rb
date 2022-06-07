class AuditCompletedAlertConfiguration < ApplicationRecord
  self.trigger_rule_fields = %i[execution_reason_name]
  self.user_facing_alert_name = 'Audit Completed'
end
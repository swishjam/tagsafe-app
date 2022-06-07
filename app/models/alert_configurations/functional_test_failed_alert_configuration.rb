class FunctionalTestFailedAlertConfiguration < AlertConfiguration
  self.trigger_rule_fields = %i[execution_reason_name]
end
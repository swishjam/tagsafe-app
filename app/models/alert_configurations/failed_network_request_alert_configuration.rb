class FailedNetworkRequestAlertConfiguration < AlertConfiguration
  self.trigger_rule_fields = %i[num_consecutive_failed_requests]
end
class FailedNetworkRequestAlertConfiguration < AlertConfiguration
  self.trigger_rule_fields = %i[num_consecutive_failed_requests]
  self.user_facing_alert_name = 'Tag endpoint failed request'
end
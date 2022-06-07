class SlowNetworkResponseAlertConfiguration < AlertConfiguration
  self.trigger_rule_fields = %i[response_ms_thresold]
end
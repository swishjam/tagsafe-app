class SlowNetworkResponseAlertConfiguration < AlertConfiguration
  self.trigger_rule_fields = %i[response_ms_thresold]
  self.user_facing_alert_name = 'Tag endpoint returning slow responses'
end
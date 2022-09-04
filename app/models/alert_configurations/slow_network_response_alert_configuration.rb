class SlowNetworkResponseAlertConfiguration < AlertConfiguration
  self.user_facing_alert_name = 'Tag endpoint returning slow responses'
  self.user_facing_alert_description = 'An alert will be triggered anytime a tag\'s endpoint is responding slowly.'
end
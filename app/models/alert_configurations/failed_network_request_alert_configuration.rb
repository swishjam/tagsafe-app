class FailedNetworkRequestAlertConfiguration < AlertConfiguration
  self.user_facing_alert_name = 'Tag endpoint failed request'
  self.user_facing_alert_description = 'An alert will be triggered anytime a tag\'s JS endpoint returns a failed status code.'
end
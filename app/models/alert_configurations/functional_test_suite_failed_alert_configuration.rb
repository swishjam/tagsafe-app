class FunctionalTestSuiteFailedAlertConfiguration < AlertConfiguration
  self.user_facing_alert_name = 'Functional test suite failed'
  self.user_facing_alert_description = 'An alert will be triggered anytime a functional test suite does not pass.'
end
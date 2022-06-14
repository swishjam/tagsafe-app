class FunctionalTestSuiteFailedAlertConfiguration < AlertConfiguration
  self.user_facing_alert_name = "Functional test suite failed"
  self.user_facing_alert_description = 'An alert will be triggered anytime one of your subscribed tag\'s test suite does not pass'
  self.has_trigger_rules = false

  def trigger_rules_description
    self.class.user_facing_alert_description
  end

  def triggered_alert_description(triggered_alert)
    "Your #{triggered_alert.tag.try_friendly_name} did not pass its test suite, it has #{triggered_alert.initiating_record.num_failed_functional_tests} failing tests."
  end
end
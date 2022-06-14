class NewTagAlertConfiguration < AlertConfiguration
  self.user_facing_alert_name = "New tag added to site"
  self.user_facing_alert_description = 'An alert will be triggered anytime a new tag is added to your site.'
  self.has_trigger_rules = false

  def trigger_rules_description
    self.class.user_facing_alert_description
  end

  def triggered_alert_description(triggered_alert)
    "Your #{triggered_alert.tag.try_friendly_name} now has a #{trigger_rules.human_exceeded_metric(capitalize: true)} of #{triggered_alert.initiating_record.preferred_delta_performance_audit.send(trigger_rules.exceeded_metric)}, exceeding your threshold of #{trigger_rules.human_exceeded_metric_value}."
  end
end
class NewTagVersionAlertConfiguration < AlertConfiguration
  self.user_facing_alert_name = 'New tag version released'
  self.user_facing_alert_description = 'An alert will be triggered anytime one of your subscribed tags makes a change to their JS.'
  self.has_trigger_rules = false

  def trigger_rules_description
    self.class.user_facing_alert_description
  end
  
  def triggered_alert_description(triggered_alert)
    "Your #{triggered_alert.tag.try_friendly_name} released a new version (for your #{triggered_alert.tag.container.name} container)."
  end
end
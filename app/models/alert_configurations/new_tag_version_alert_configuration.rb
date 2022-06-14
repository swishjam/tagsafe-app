class NewTagVersionAlertConfiguration < AlertConfiguration
  self.user_facing_alert_name = 'New tag version released'
  self.user_facing_alert_description = 'An alert will be triggered anytime a tag makes a change to their JS.'

  def triggered_alert_description(triggered_alert)
    "Your #{triggered_alert.tag.try_friendly_name} released a new version to #{triggered_alert.tag.domain.url_hostname}."
  end
end
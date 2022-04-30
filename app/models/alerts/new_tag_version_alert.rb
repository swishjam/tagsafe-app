class NewTagVersionAlert < TriggeredAlert
  self.send_notification_in_new_job = false
  
  def send_alert_notification_if_necessary!(alert_config)
    return unless alert_config.alert_on_new_tag_versions
    TagsafeEmail::NewTagVersion.new(alert_config.domain_user.user, initiating_record).send!
    true
  end
end
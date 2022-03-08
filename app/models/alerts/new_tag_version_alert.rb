class NewTagVersionAlert < TriggeredAlert
  def send_alert_notification_if_necessary!(alert_config)
    return unless alert_config.alert_on_new_tag_versions
    TagsafeMailer.send_new_tag_version_email(alert_config.domain_user.user, tag_version)
    true
  end
end
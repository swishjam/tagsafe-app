class NewTagAlert < TriggeredAlert
  def send_alert_notification_if_necessary!(alert_config)
    return unless alert_config.alert_on_new_tags
    TagsafeMailer.send_new_tag_detected_email(alert_config.domain_user.user, tag)
    true
  end

  # override `TriggeredAlert` defintion because it is a domain-specific config
  def tag_specific_alert_configuration_or_default(domain_user)
    domain_user.domain_alert_configuration
  end
end
class EmitAlertNotificationsJob < ApplicationJob
  queue_as TagsafeQueue.NORMAL

  def perform(triggered_alert)
    triggered_alert.tag.domain.domain_users.each do |domain_user|
      alert_config = triggered_alert.tag_specific_alert_configuration_or_default(domain_user)
      if triggered_alert.send_alert_notification_if_necessary!(alert_config)
        triggered_alert.triggered_alert_domain_users.create!(domain_user: domain_user)
      end
    end
  end
end
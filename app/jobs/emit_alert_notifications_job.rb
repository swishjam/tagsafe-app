class EmitAlertNotificationsJob < ApplicationJob
  queue_as TagsafeQueue.NORMAL

  def perform(triggered_alert)
    triggered_alert.tag.container.container_users.each do |container_user|
      alert_config = triggered_alert.tag_specific_alert_configuration_or_default(container_user)
      if triggered_alert.send_alert_notification_if_necessary!(alert_config)
        triggered_alert.triggered_alert_container_users.create!(container_user: container_user)
      end
    end
  end
end
class NotificationModerator::AuditNotifier
  def initialize(audit)
    @audit = audit
  end

  def notify!
    notify_email_subscribers
    notify_slack_subscribers
  end

  private

  def notify_email_subscribers
    # @audit.tag.audit_complete_notification_subscribers.should_receive_notifications.each do |notification_subscriber| 
    #   notification_subscriber.send_email!(@audit)
    # end
  end

  def notify_slack_subscribers
    # @audit.tag.audit_completed_slack_notifications.should_receive_notifications.each do |slack_notification| 
    #   slack_notification.notify!(@audit)
    # end
  end
end
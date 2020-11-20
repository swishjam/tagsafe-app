class AuditCompleteNotificationSubscriber < NotificationSubscriber
  def self.friendly_name
    'audit completed'
  end

  def send_email!(audit)
    AuditCompleteMailer.send_audit_completed_email(audit, user).deliver
  end
end
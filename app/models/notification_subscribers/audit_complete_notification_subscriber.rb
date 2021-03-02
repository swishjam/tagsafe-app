class AuditCompleteNotificationSubscriber < EmailNotificationSubscriber
  def self.friendly_name
    'audit completed'
  end

  def send_email!(audit)
    TagSafeMailer.send_audit_completed_email(audit, user)
  end
end
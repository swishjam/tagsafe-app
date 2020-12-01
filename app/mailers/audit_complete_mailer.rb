class AuditCompleteMailer < ApplicationMailer
  def send_audit_completed_email(audit, user)
    @audit = audit
    @script_subscriber = @audit.script_subscriber
    @previous_audit = @script_subscriber.primary_audit_by_script_change(@script_subscriber.script.most_recent_change&.previous_change)
    mail(to: user.email, subject: "Audit for #{@script_subscriber.try_friendly_name} completed.")
  end
end
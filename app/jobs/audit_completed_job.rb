class AuditCompletedJob < ApplicationJob
  def perform(audit)
    audit.script_subscriber.send_audit_complete_notifications!(audit)
  end
end
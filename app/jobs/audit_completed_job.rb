class AuditCompletedJob < ApplicationJob
  def perform(audit)
    unless audit.execution_reason == ExecutionReason.INITIAL_AUDIT
      NotificationModerator::AuditNotifier.new(audit).notify!
    end
  end
end
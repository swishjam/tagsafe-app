class AuditCompletedJob < ApplicationJob
  def perform(audit)
    audit.script_subscriber.send_audit_complete_notifications!(audit)
    # TODO: need to account for retry execution types
    unless audit.performance_audit_failed? || ![ExecutionReason.REACTIVATED_TAG, ExecutionReason.TAG_CHANGE].include?(audit.execution_reason)
      BackfillChartDataJob.perform_later(audit)
    end
  end
end
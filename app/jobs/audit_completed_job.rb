class AuditCompletedJob < ApplicationJob
  def perform(audit)
    NotificationModerator::AuditNotifier.new(audit).notify!
    # TODO: need to account for retry execution types
    # unless audit.performance_audit_failed? || ![ExecutionReason.REACTIVATED_TAG, ExecutionReason.TAG_CHANGE].include?(audit.execution_reason)
    #   BackfillChartDataJob.perform_later(audit)
    # end
  end
end
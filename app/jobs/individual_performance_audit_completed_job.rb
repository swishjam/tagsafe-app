class IndividualPerformanceAuditCompletedJob < ApplicationJob
  def perform(results:, logs:, individual_performance_audit_id:, error:)
    evaluator = PerformanceAuditManager::EvaluateIndividualResults.new(
      individual_performance_audit_id: individual_performance_audit_id,
      results: results,
      logs: logs,
      error: error
    )
    if evaluator.already_processed?
      Rails.logger.warn "Already processed IndividualPerformanceAudit #{individual_performance_audit_id}, bypassing..."
    else
      evaluator.evaluate!
      audit = evaluator.individual_performance_audit.audit
      if !audit.performance_audit_failed? && audit.all_individual_performance_audits_completed?
        audit.create_delta_performance_audit!
        audit.completed!
      end
    end
  end
end
class PerformanceAuditCompletedJob < ApplicationJob
  def perform(error:, results_with_tag:, results_without_tag:, audit_id:, with_tag_logs:, without_tag_logs:)
    PerformanceAuditManager::EvaluateResults.new(
      error: error,
      results_with_tag: results_with_tag,
      results_without_tag: results_without_tag,
      audit_id: audit_id,
      with_tag_logs: with_tag_logs,
      without_tag_logs: without_tag_logs
    ).evaluate!
  end
end
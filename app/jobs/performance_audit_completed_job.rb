class PerformanceAuditCompletedJob < ApplicationJob
  def perform(error:, results_with_tag:, results_without_tag:, audit_id:, num_attempts:)
    PerformanceAuditManager::EvaluateResults.new(
      error: error,
      audit_id: audit_id,
      results_with_tag: results_with_tag,
      results_without_tag: results_without_tag,
      num_attempts: num_attempts
    ).evaluate!
  end
end
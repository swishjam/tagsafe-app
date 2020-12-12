class GeppettoModerator::Receivers::PerformanceAuditCompleted
  def initialize(error:, results_with_tag:, results_without_tag:, audit_id:, with_tag_logs:, without_tag_logs:, num_attempts:)
    @error = error
    @results_with_tag = results_with_tag
    @results_without_tag = results_without_tag
    @audit_id = audit_id
    @with_tag_logs = with_tag_logs
    @without_tag_logs = without_tag_logs
    @num_attempts = num_attempts
  end

  def receive!
    PerformanceAuditCompletedJob.perform_later(
      error: @error,
      results_with_tag: @results_with_tag,
      results_without_tag: @results_without_tag,
      audit_id: @audit_id,
      with_tag_logs: @with_tag_logs,
      without_tag_logs: @without_tag_logs,
      num_attempts: @num_attempts
    )
  end
end
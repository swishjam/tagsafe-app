class GeppettoModerator::Receivers::LighthouseAuditCompleted
  def initialize(error:, results_with_tag:, results_without_tag:, audit_id:)
    @error = error
    @results_with_tag = results_with_tag
    @results_without_tag = results_without_tag
    @audit_id = audit_id
  end

  def receive!
    LighthouseAuditResultsEvaluatorJob.perform_later(
      error: @error,
      results_with_tag: @results_with_tag,
      results_without_tag: @results_without_tag,
      audit_id: @audit_id
    )
  end
end
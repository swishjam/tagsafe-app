class AuditRunner
  include Rails.application.routes.url_helpers
  
  def initialize(tag_version:, execution_reason:, attempt_number:)
    @tag_version = tag_version
    @tag = @tag_version.tag
    @execution_reason = execution_reason
    @attempt_number = attempt_number
  end

  def run!
    run_performance_audit!
  end

  private

  def run_performance_audit!
    @tag.tag_preferences.performance_audit_iterations.times do
      create_performance_audit_runner_with_tag.send!
      create_performance_audit_runner_without_tag.send!
    end
  end

  def create_performance_audit_runner_with_tag
    GeppettoModerator::LambdaSenders::PerformanceAuditerWithTag.new(
      audit: audit,
      tag_version: @tag_version
    )
  end

  def create_performance_audit_runner_without_tag
    GeppettoModerator::LambdaSenders::PerformanceAuditerWithoutTag.new(
      audit: audit,
      tag_version: @tag_version
    )
  end

  def audit
    @audit ||= Audit.create(
      tag_version: @tag_version,
      tag: @tag,
      execution_reason: @execution_reason,
      page_url_performance_audit_performed_on: tag_preferences.page_url_to_perform_audit_on,
      enqueued_at: DateTime.now,
      performance_audit_iterations: tag_preferences.performance_audit_iterations,
      attempt_number: @attempt_number,
      primary: false
    )
  end
  
  def tag_preferences
    @tag_preferences ||= @tag.tag_preferences
  end
end

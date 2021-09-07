class AuditRunner
  include Rails.application.routes.url_helpers
  
  def initialize(tag_version:, execution_reason:, num_attempts: 0)
    @tag_version = tag_version
    @tag = @tag_version.tag
    @execution_reason = execution_reason
    @num_attempts = num_attempts
  end

  def run!
    performance_audit_runner.send!
  end

  private

  def run_performance_audit
    @tag.tag_preferences.num_test_iterations.times do
      performance_audit_runner_with_tag.send!
      performance_audit_runner_without_tag.send!
    end
  end

  def performance_audit_runner_with_tag
    @performance_audit_runner ||= GeppettoModerator::LambdaSenders::PerformanceAuditer::WithTag.new(
      audit: audit,
      tag_version: @tag_version
    )
  end

  def performance_audit_runner_without_tag
    GeppettoModerator::LambdaSenders::PerformanceAuditer::WithoutTag.new(
      audit: audit,
      tag_version: @tag_version
    )
  end

  def audit
    @audit ||= Audit.create(
      tag_version: @tag_version,
      tag: @tag,
      execution_reason: @execution_reason,
      performance_audit_url: @tag.tag_preferences.url_to_audit,
      performance_audit_enqueued_at: DateTime.now,
      performance_audit_iterations: @tag.tag_preferences.num_test_iterations,
    )
  end
end

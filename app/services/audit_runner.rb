class AuditRunner
  class InvalidAuditRun < StandardError; end;
  def initialize(audit:, tag_version:, url_to_audit_id:, execution_reason:, enable_tracing:, attempt_number:)
    @tag_version = tag_version
    @url_to_audit_id = url_to_audit_id
    @tag = @tag_version.tag
    @execution_reason = execution_reason
    @attempt_number = attempt_number
    @enable_tracing = enable_tracing
    @audit = audit || create_audit
  end

  def perform_later
    RunAuditOnTagVersionJob.perform_later(job_args)
    @audit
  end

  def perform_now
    RunAuditOnTagVersionJob.perform_now(job_args)
    @audit
  end

  def run!
    run_performance_audit!
  end

  private

  def job_args
    {
      audit: @audit,
      tag_version: @tag_version,
      url_to_audit_id: @url_to_audit_id,
      execution_reason: @execution_reason,
      attempt_number: @attempt_number,
      enable_tracing: @enable_tracing
    }
  end

  def create_audit
    @audit ||= Audit.create!(
      tag_version: @tag_version,
      tag: @tag,
      execution_reason: @execution_reason,
      audited_url_id: @url_to_audit_id,
      performance_audit_iterations: tag_preferences.performance_audit_iterations,
      attempt_number: @attempt_number,
      primary: false
    )
  end

  def run_performance_audit!
    audit.update(enqueued_at: DateTime.now)
    number_of_performance_audits_to_run.times do
      RunIndividualPerformanceAuditJob.perform_later(audit: @audit, tag_version: @tag_version, enable_tracing: @enable_tracing, performance_audit_type: :with_tag)
      RunIndividualPerformanceAuditJob.perform_later(audit: @audit, tag_version: @tag_version, enable_tracing: @enable_tracing, performance_audit_type: :without_tag)
    end
  end

  def number_of_performance_audits_to_run
    @tag.tag_preferences.performance_audit_iterations
  end

  def audit
    @audit ||= Audit.create!(
      tag_version: @tag_version,
      tag: @tag,
      execution_reason: @execution_reason,
      audited_url_id: @url_to_audit_id,
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

class AuditRunner
  def initialize(audit:, tag_version:, url_to_audit_id:, execution_reason:, options: {})
    @tag_version = tag_version
    @url_to_audit_id = url_to_audit_id
    @tag = @tag_version.tag
    @execution_reason = execution_reason
    @options = options
    @audit = audit || create_audit
  end

  def perform_later
    RunAuditOnTagVersionJob.perform_later(job_args)
    audit
  end

  def perform_now
    RunAuditOnTagVersionJob.perform_now(job_args)
    audit
  end

  def run!
    run_performance_audit!
  end

  private

  def job_args
    {
      audit: audit,
      tag_version: @tag_version,
      url_to_audit_id: @url_to_audit_id,
      execution_reason: @execution_reason
    }
  end

  def run_performance_audit!
    audit.update(enqueued_at: DateTime.now)
    @tag.tag_preferences.performance_audit_iterations.times do
      RunIndividualPerformanceAuditJob.perform_later(perf_audit_job_args(:with_tag))
      RunIndividualPerformanceAuditJob.perform_later(perf_audit_job_args(:without_tag))
    end
  end

  def perf_audit_job_args(audit_type)
    {
      type: audit_type,
      audit: @audit,
      tag_version: @tag_version,
      options: @options
    }
  end

  def audit
    @audit ||= Audit.create!(
      performance_audit_calculator: @tag.domain.current_performance_audit_calculator,
      tag_version: @tag_version,
      tag: @tag,
      execution_reason: @execution_reason,
      page_url: url_to_audit.page_url,
      performance_audit_iterations: tag_preferences.performance_audit_iterations,
      primary: false
    )
  end
  alias create_audit audit
  
  def tag_preferences
    @tag_preferences ||= @tag.tag_preferences
  end

  def url_to_audit
    @url_to_audit ||= UrlToAudit.find(@url_to_audit_id)
  end
end

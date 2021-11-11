class AuditRunner
  def initialize(
    audit:, 
    tag_version:, 
    url_to_audit_id:, 
    execution_reason:, 
    include_page_load_resources:, 
    inline_injected_script_tags:, 
    enable_tracing:
  )
    @tag_version = tag_version
    @url_to_audit_id = url_to_audit_id
    @tag = @tag_version.tag
    @execution_reason = execution_reason
    @include_page_load_resources = include_page_load_resources
    @inline_injected_script_tags = inline_injected_script_tags
    @enable_tracing = enable_tracing
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
      execution_reason: @execution_reason,
      enable_tracing: @enable_tracing,
      include_page_load_resources: @include_page_load_resources,
      inline_injected_script_tags: @inline_injected_script_tags
    }
  end

  def run_performance_audit!
    audit.update(enqueued_at: DateTime.now)
    @tag.tag_preferences.performance_audit_iterations.times do
      run_audit_with_tag!
      run_audit_without_tag!
    end
  end

  def run_audit_with_tag!
    RunIndividualPerformanceAuditJob.perform_later(perf_audit_job_args(LambdaModerator::Senders::PerformanceAuditerWithTag))
  end

  def run_audit_without_tag!
    RunIndividualPerformanceAuditJob.perform_later(perf_audit_job_args(LambdaModerator::Senders::PerformanceAuditerWithoutTag))
  end

  def perf_audit_job_args(lambda_sender_class)
    {
      audit: @audit,
      tag_version: @tag_version,
      enable_tracing: @enable_tracing,
      include_page_load_resources: @include_page_load_resources,
      inline_injected_script_tags: @inline_injected_script_tags,
      lambda_sender_class: lambda_sender_class
    }
  end

  def audit
    @audit ||= Audit.create!(
      tag_version: @tag_version,
      tag: @tag,
      execution_reason: @execution_reason,
      audited_url_id: @url_to_audit_id,
      # enqueued_at: DateTime.now,
      performance_audit_iterations: tag_preferences.performance_audit_iterations,
      primary: false
    )
  end
  alias create_audit audit
  
  def tag_preferences
    @tag_preferences ||= @tag.tag_preferences
  end
end

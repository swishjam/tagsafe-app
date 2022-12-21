class MainThreadExecutionAuditComponent < AuditComponent
  def perform_audit!
    AuditRunnerJobs::RunMainThreadExecutionEvaluationJob.perform_later(self)
  end

  def main_thread_execution_for_tag
    raw_results['total_main_thread_execution_ms_for_tag']
  end

  def main_thread_blocking_for_tag
    raw_results['total_main_thread_blocking_ms_for_tag']
  end

  def audit_breakdown_description
    "This release from #{audit.tag.try_friendly_name} was responsible for #{main_thread_execution_for_tag.round(2)} ms of main thread execution, of which #{main_thread_blocking_for_tag.round(2)} ms of it were blocking the main thread."
  end
end
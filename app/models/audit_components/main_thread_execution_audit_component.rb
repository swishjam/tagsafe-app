class MainThreadExecutionAuditComponent < AuditComponent
  def perform_audit!
    AuditRunnerJobs::RunMainThreadExecutionEvaluationJob.perform_later(self)
  end
end
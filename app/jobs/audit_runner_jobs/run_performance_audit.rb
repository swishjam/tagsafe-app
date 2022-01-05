module AuditRunnerJobs
  class RunPerformanceAudit < ApplicationJob
    queue_as :performance_audit_runner_queue

    def perform(audit)
      audit.performance_audit_iterations.times do
        enqueue_individual_performance_audit!(audit, :with_tag)
        enqueue_individual_performance_audit!(audit, :without_tag)
      end
    end

    def enqueue_individual_performance_audit!(audit, audit_type)
      AuditRunnerJobs::RunIndividualPerformanceAudit.perform_later({
        type: audit_type,
        audit: audit,
        tag_version: audit.tag_version
      })
    end
  end
end
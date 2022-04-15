module AuditRunnerJobs
  class RunDomainAudit < ApplicationJob
    queue_as TagsafeQueue.CRITICAL
    
    NUM_PERFORMANCE_AUDITS_PER_DOMAIN_AUDIT = (ENV['NUM_PERFORMANCE_AUDITS_PER_DOMAIN_AUDIT'] || 3).to_i
    
    def perform(domain_audit)
      NUM_PERFORMANCE_AUDITS_PER_DOMAIN_AUDIT.times do
        StepFunctionInvoker::DomainAuditer.new(domain_audit, IndividualPerformanceAuditWithTag).send!
        StepFunctionInvoker::DomainAuditer.new(domain_audit, IndividualPerformanceAuditWithoutTag).send!
      end
    end
  end
end
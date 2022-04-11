module LambdaEventResponses
  class DomainAuditResult < PerformanceAuditResult
    # do we ever want to run a second batch of performance audits? or just fail the 
    # entire DomainAudit if we dont have any successful performance audits
    def enqueue_next_batch_of_performance_audits_if_necessary
      return if domain_audit.performance_audits.pending.any?
      if domain_audit.delta_performance_audits.none?
        domain_audit.failed!("Unable to create successful performance audit, tried #{domain_audit.performance_audits.count/2} times.")
      else
        domain_audit.completed!
      end
    end

    def domain_audit
      @domain_audit ||= individual_performance_audit.domain_audit
    end

    def valid?
      error.nil?
    end
  end
end
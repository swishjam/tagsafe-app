module AuditRunnerJobs
  class RunPerformanceAudit < ApplicationJob
    include RetriableJob
    queue_as :performance_audit_runner_queue

    def perform(audit)
      while (audit.num_individual_performance_audits_with_tag_remaining > 0 || 
              audit.num_individual_performance_audits_without_tag_remaining > 0) &&
              audit.individual_performance_audits.failed.count <= audit.maximum_individual_performance_audit_attempts
        run_individual_performance_audit(audit, :without_tag) unless audit.num_individual_performance_audits_without_tag_remaining.zero?
        run_individual_performance_audit(audit, :with_tag) unless audit.num_individual_performance_audits_with_tag_remaining.zero?
        audit.reload
      end
      
      unless audit.all_individual_performance_audits_completed?
        Resque.logger.error "AuditRunerJobs::RunPerformanceAudit unable to successfully complete, attempted #{audit.individual_performance_audits.count} audits. Stopping attempts and failing..."
        audit.performance_audit_error!("Haulting Performance Audit retries on audit due to exceeding max retry count of #{audit.maximum_individual_performance_audit_attempts}")
      else
        Resque.logger.info "AuditRunnerJobs::RunPerformanceAudit completed successfully!"
        audit.performance_audit_completed!
      end
    end

    def run_individual_performance_audit(audit, audit_type)
      Resque.logger.info "AuditRunnerJobs::RunPerformanceAudit running individual performance audit for Audit #{audit.id} `#{audit_type}`"
      performance_auditer = LambdaModerator::PerformanceAuditer.new(
        type: audit_type,
        audit: audit, 
        tag_version: audit.tag_version, 
        # options: options
      )
      response = performance_auditer.send!
      individual_performance_audit = performance_auditer.individual_performance_audit
      if response.successful
        capture_successful_individual_performance_audit_response(response.response_body, individual_performance_audit)
      else
        individual_performance_audit.error!(response.error)
      end
    end

    def capture_successful_individual_performance_audit_response(response_data, individual_performance_audit)
      PerformanceAuditManager::ResultsCapturer.new(
        individual_performance_audit: individual_performance_audit,
        results: response_data['results'], 
        puppeteer_recording: response_data['screen_recording'],
        blocked_resources: response_data['blocked_resources'],
        logs: response_data['logs'],
        error: response_data['error'] || response_data['errorMessage']
      ).capture_results!
    end
    
    def self.on_retriable_job_failure(exception, audit)
      audit.performance_audit_error!('An unexpected error occurred.')
    end
  end
end
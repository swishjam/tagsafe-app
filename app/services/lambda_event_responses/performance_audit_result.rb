module LambdaEventResponses
  class PerformanceAuditResult < Base
    def process_results!
      PerformanceAuditManager::ResultsCapturer.new(self).capture_results!
      try_to_calculate_delta_results_and_run_next_set_of_audits!
    end

    def individual_performance_audit
      @individual_performance_audit ||= PerformanceAudit.find(request_payload['individual_performance_audit_id'])
    end

    def performance_metrics
      @performance_results ||= LambdaEventResponses::PerformanceAuditResult::PerformanceMetrics.new(response_payload['results'] || {})
    end

    def puppeteer_recording
      @puppeteer_recording ||= LambdaEventResponses::PerformanceAuditResult::PuppeteerRecording.new(response_payload['screen_recording'] || {})
    end

    def blocked_resources
      @blocked_resources ||= LambdaEventResponses::PerformanceAuditResult::BlockedResources.new(response_payload['blocked_resources'] || [])
    end

    def page_load_resources
      @page_load_resources ||= LambdaEventResponses::PerformanceAuditResult::PageLoadResources.new((response_payload['results'] || {})['page_load_resources'] || [])
    end

    def logs
      @logs ||= response_payload['logs']
    end

    def has_logs?
      !logs.blank?
    end

    def page_trace_s3_url
      @page_trace_s3_url ||= response_payload['tracing_results_s3_url']
    end

    def error
      @error ||= response_payload['error'] || response_payload['errorMessage']
    end

    private

    def try_to_calculate_delta_results_and_run_next_set_of_audits!
      unless individual_performance_audit.audit.completed?
        create_delta_performance_audit_if_necessary
        enqueue_next_batch_of_performance_audits_if_necessary
      end
    end

    def create_delta_performance_audit_if_necessary
      return if error.present?
      PerformanceAuditManager::DeltaPerformanceAuditCreator.find_matching_performance_audit_and_create!(individual_performance_audit)
    end

    def enqueue_next_batch_of_performance_audits_if_necessary
      return unless processed_all_performance_audit_results_in_batch?
      PerformanceAuditManager::QueueMaintainer.new(individual_performance_audit.audit).run_next_batch_of_performance_audits_or_mark_as_completed!
    end

    def processed_all_performance_audit_results_in_batch?
      individual_performance_audit
                              .audit
                              .reload
                              .performance_audits
                              .in_batch(individual_performance_audit.batch_identifier)
                              .pending
                              .none?
    end
  end
end
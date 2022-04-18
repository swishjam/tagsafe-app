module StepFunctionResponses
  class PerformanceAuditResult < Base
    def process_results!
      PerformanceAuditManager::ResultsCapturer.new(self).capture_results!
      try_to_calculate_delta_results_and_run_next_set_of_audits!
    end

    def individual_performance_audit
      @individual_performance_audit ||= PerformanceAudit.includes(:audit).find(request_payload['individual_performance_audit_id'])
    end
    alias record individual_performance_audit

    def audit
      @audit ||= individual_performance_audit.audit
    end

    def valid?
      return @valid if defined?(@valid)
      @valid = step_function_successful? && error.nil? && blocked_correct_resources_for_audit_type?
    end

    def invalid?
      !valid?
    end

    def performance_metrics
      @performance_results ||= StepFunctionResponses::PerformanceAuditResult::PerformanceMetrics.new(response_payload['results'] || {})
    end

    def puppeteer_recording
      @puppeteer_recording ||= StepFunctionResponses::PerformanceAuditResult::PuppeteerRecording.new(response_payload['screen_recording'] || {})
    end

    def blocked_resources
      @blocked_resources ||= StepFunctionResponses::PerformanceAuditResult::BlockedResources.new(response_payload['blocked_resources'] || [])
    end

    def page_load_resources
      @page_load_resources ||= StepFunctionResponses::PerformanceAuditResult::PageLoadResources.new((response_payload['results'] || {})['page_load_resources'] || [])
    end

    def allowed_request_urls
      @allowed_request_urls ||= response_payload['cached_requests'].concat(response_payload['not_cached_requests'])
    end

    def audited_tag_url
      audit.ran_on_live_tag? ? audit.tag.url_based_on_preferences : audit.tag_version.js_file_url
    end

    def bytes
      @bytes ||= individual_performance_audit.calculate_bytes || 0
    end

    def blocked_correct_resources_for_audit_type?
      return @blocked_correct_resources_for_audit_type if defined?(@blocked_correct_resources_for_audit_type)
      case individual_performance_audit.class.to_s
      when IndividualPerformanceAuditWithTag.to_s
        @blocked_correct_resources_for_audit_type = allowed_request_urls.any?{ |url| url.include?(audited_tag_url) }
        unless @blocked_correct_resources_for_audit_type
          @invalid_audit_error = "The #{audit.tag.url_based_on_preferences} tag was not found during the performance audit, therefore results would be inaccurate."
        end
      when IndividualPerformanceAuditWithoutTag.to_s
        @blocked_correct_resources_for_audit_type = allowed_request_urls.none?{ |url| url.include?(audited_tag_url) }
        unless @blocked_correct_resources_for_audit_type
          @invalid_audit_error = "The #{audit.tag.url_based_on_preferences} tag was not blocked during the performance audit, therefore results would be inaccurate."
        end
      else
        raise StandardError, "Invalid individual performance audit type in PerformanceAuditResult: #{individual_performance_audit.class.to_s}"
      end
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
      @error ||= step_function_error_message || response_payload['error'] || response_payload['errorMessage'] || @invalid_audit_error
    end

    private

    def try_to_calculate_delta_results_and_run_next_set_of_audits!
      unless (individual_performance_audit.audit || individual_performance_audit.domain_audit).completed?
        create_delta_performance_audit_if_successful
        enqueue_next_batch_of_performance_audits_if_necessary
      end
    end

    def create_delta_performance_audit_if_successful
      return if error.present?
      PerformanceAuditManager::DeltaPerformanceAuditCreator.find_matching_performance_audit_and_create!(individual_performance_audit)
    end

    def enqueue_next_batch_of_performance_audits_if_necessary
      return unless processed_all_performance_audit_results_in_batch?
      PerformanceAuditManager::QueueMaintainer.new(individual_performance_audit.audit).run_next_batch_of_performance_audits_or_mark_as_completed!
    end

    def processed_all_performance_audit_results_in_batch?
      audit.reload.performance_audits.in_batch(individual_performance_audit.batch_identifier).pending.none?
    end

    def audit
      @audit ||= individual_performance_audit.audit
    end
  end
end
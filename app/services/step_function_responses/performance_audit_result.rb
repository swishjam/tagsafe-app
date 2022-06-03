module StepFunctionResponses
  class PerformanceAuditResult < Base
    def process_results!
      PerformanceAuditManager::ResultsCapturer.new(self).capture_results!
      try_to_calculate_delta_results_and_run_next_set_of_audits!
      TagsafeAws::S3.delete_object_by_s3_url(response_payload['performance_audit_results_s3_url']) unless response_payload['performance_audit_results_s3_url'].nil?
    end

    def parsed_results
      return {} if step_function_failed?
      @parsed_results ||= begin
        if response_payload['performance_audit_results_s3_url']
          JSON.parse(TagsafeAws::S3.get_object_by_s3_url(response_payload['performance_audit_results_s3_url']).body.read)
        else
          raise StandardError, <<~ERR
            PerformanceAuditResult cannot get performance audit result. Expected `responsePayload` to contain 
            'performance_audit_results_s3_url' key, instead it contained: #{response_payload}
          ERR
        end
      end
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
      @valid = step_function_successful? && error.nil? && blocked_correct_resources_for_audit_type? && speed_index_successful_if_required?
    end

    def invalid?
      !valid?
    end

    def performance_metrics
      @performance_results ||= StepFunctionResponses::PerformanceAuditResult::PerformanceMetrics.new(parsed_results['results'] || {})
    end

    def puppeteer_recording
      @puppeteer_recording ||= StepFunctionResponses::PerformanceAuditResult::PuppeteerRecording.new(parsed_results['screen_recording'] || {})
    end

    def blocked_resources
      @blocked_resources ||= StepFunctionResponses::PerformanceAuditResult::BlockedResources.new(parsed_results['blocked_resources'] || [])
    end

    def page_load_resources
      @page_load_resources ||= StepFunctionResponses::PerformanceAuditResult::PageLoadResources.new((parsed_results['results'] || {})['page_load_resources'] || [])
    end

    def speed_index_results
      @speed_index_results ||= StepFunctionResponses::PerformanceAuditResult::SpeedIndexResults.new(parsed_results['speed_index'] || {})
    end

    def main_thread_results
      @main_thread_results ||= StepFunctionResponses::PerformanceAuditResult::MainThreadResults.new(parsed_results['main_thread_results'] || {})
    end

    def allowed_request_urls
      @allowed_request_urls ||= parsed_results['cached_requests'].concat(parsed_results['not_cached_requests'])
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

    def speed_index_successful_if_required?
      return true if Util.env_is_true('DONT_FAIL_PERFORMANCE_AUDIT_WITH_SPEED_INDEX_ERRORS')
      return true unless speed_index_results.failed?
      return true if individual_performance_audit.audit.performance_audit_calculator.speed_index_weight.zero? && individual_performance_audit.audit.performance_audit_calculator.perceptual_speed_index_weight.zero?
      @invalid_audit_error = "Error generating Speed Index, cannot calculate Tagsafe Score: #{speed_index_results.error_message}"
      false
    end

    def logs
      @logs ||= parsed_results['logs']
    end

    def has_logs?
      !logs.blank?
    end

    def has_page_load_resources?
      ((parsed_results['results'] || {})['page_load_resources'] || []).any?
    end

    def has_blocked_resources?
      blocked_resources.filtered.any?
    end

    def page_trace_s3_url
      @page_trace_s3_url ||= parsed_results['tracing_results_s3_url']
    end

    def error
      @error ||= step_function_error_message || parsed_results['error'] || parsed_results['errorMessage'] || @invalid_audit_error
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
module PerformanceAuditManager
  class PerformanceAuditSetGenerator
    attr_accessor :performance_audit_with_tag, :performance_audit_without_tag

    def initialize(audit)
      @audit = audit
    end

    def generate_performance_audit_set!
      generate_performance_audit_with_tag!
      generate_performance_audit_without_tag!
      generate_delta_performance_audit!
    end

    private

    def generate_performance_audit_with_tag!
      return if @audit.performance_audit_failed?
      @performance_audit_with_tag ||= run_performance_audit!(IndividualPerformanceAuditWithTag)
    end

    def generate_performance_audit_without_tag!
      return if @audit.performance_audit_failed?
      @performance_audit_without_tag ||= run_performance_audit!(IndividualPerformanceAuditWithoutTag)
    end

    def generate_delta_performance_audit!
      return if @audit.performance_audit_failed?
      PerformanceAuditManager::DeltaPerformanceAuditCreator.new(
        performance_audit_with_tag: performance_audit_with_tag,
        performance_audit_without_tag: performance_audit_without_tag,
      ).create_delta_performance_audit!
    end

    def run_performance_audit!(performance_audit_klass)
      return if @audit.performance_audit_failed?
      performance_auditer = LambdaModerator::PerformanceAuditer.new(
        audit: @audit,
        performance_audit_klass: performance_audit_klass
        # options: options
      )
      response = performance_auditer.send!
      if response.successful
        capture_successful_response(response.response_body, performance_auditer.individual_performance_audit)
        performance_auditer.individual_performance_audit
      else
        performance_audit_failed(performance_audit.individual_performance_audit, response.error)
      end
    end

    def capture_successful_response(response_data, individual_performance_audit)
      PerformanceAuditManager::ResultsCapturer.new(
        individual_performance_audit: individual_performance_audit,
        results: response_data['results'], 
        page_trace_s3_url: response_data['tracing_results_s3_url'],
        puppeteer_recording: response_data['screen_recording'],
        blocked_resources: response_data['blocked_resources'],
        logs: response_data['logs'],
        error: response_data['error'] || response_data['errorMessage']
      ).capture_results!
    end

    def performance_audit_failed!(performance_audit, error)
      performance_audit.error!(error)
      if @audit.reached_maximum_failed_performance_audits?
        @audit.performance_audit_error!("Reached maximum failed performance audits of #{audit.maximum_individual_performance_audit_attempts}")
      else
        run_performance_audit!(performance_audit.class)
      end
    end
  end
end
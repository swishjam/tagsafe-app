module PerformanceAuditManager
  class ResultsCapturer
    attr_reader :individual_performance_audit, :performance_audit_result

    def initialize(performance_audit_result_obj)
      @performance_audit_result = performance_audit_result_obj
      @individual_performance_audit = performance_audit_result.individual_performance_audit
    end

    def capture_results!
      return if individual_performance_audit.completed?
      update_individual_performance_audits_results_with_results!
      if performance_audit_result.error
        individual_performance_audit.error!(performance_audit_result.error)
      else
        individual_performance_audit.completed!
      end
    end

    private

    def update_individual_performance_audits_results_with_results!
      individual_performance_audit.update!(performance_audit_attrs)
      individual_performance_audit.update(performance_audit_children_attrs)
    end

    def performance_audit_attrs
      {
        dom_complete: performance_audit_result.performance_metrics.dom_complete,
        dom_content_loaded: performance_audit_result.performance_metrics.dom_content_loaded,
        dom_interactive: performance_audit_result.performance_metrics.dom_interactive,
        first_contentful_paint: performance_audit_result.performance_metrics.first_contentful_paint,
        layout_duration: performance_audit_result.performance_metrics.layout_duration,
        script_duration: performance_audit_result.performance_metrics.script_duration,
        task_duration: performance_audit_result.performance_metrics.task_duration,
        page_trace_s3_url: performance_audit_result.page_trace_s3_url
      }
    end

    def performance_audit_children_attrs
      attrs = {}
      if should_capture_page_resources_attributes?
        attrs[:page_load_resources_attributes] = performance_audit_result.page_load_resources.formatted
        attrs[:blocked_resources_attributes] = performance_audit_result.blocked_resources.filtered
      end
      attrs[:performance_audit_log_attributes] = { logs: performance_audit_result.logs } if performance_audit_result.has_logs?
      attrs[:puppeteer_recording_attributes] = performance_audit_result.puppeteer_recording.formatted_results if performance_audit_result.puppeteer_recording.included_and_valid?
      attrs
    end

    def should_capture_page_resources_attributes?
      individual_performance_audit.audit.include_page_load_resources
    end
  end
end
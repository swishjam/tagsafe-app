module PerformanceAuditManager
  class ResultsCapturer
    attr_reader :individual_performance_audit
    def initialize(
      individual_performance_audit:, 
      results:, 
      page_trace_s3_url:,
      puppeteer_recording:,
      blocked_resources:,
      logs:,
      error:
    )
      @individual_performance_audit = individual_performance_audit
      # when lambda function times out, results are nil but is still a 200 response code
      @results = results || {}
      @page_trace_s3_url = page_trace_s3_url
      @puppeteer_recording = puppeteer_recording || {}
      @blocked_resources = blocked_resources || []
      @logs = logs || ''
      @error = error
    end

    def capture_results!
      return if @individual_performance_audit.completed?
      update_individual_performance_audits_results_with_results!
      if @error
        individual_performance_audit.error!(@error)
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
        dom_complete: @results['DOMComplete'],
        dom_content_loaded: @results['DOMContentLoaded'],
        dom_interactive: @results['DOMInteractive'],
        first_contentful_paint: @results['FirstContentfulPaint'],
        layout_duration: @results['LayoutDuration'],
        script_duration: @results['ScriptDuration'],
        task_duration: @results['TaskDuration'],
        page_trace_s3_url: @page_trace_s3_url
      }
    end

    def performance_audit_children_attrs
      attrs = {
        page_load_resources_attributes: formatted_page_load_resources,
        blocked_resources_attributes: @blocked_resources.select{ |resource| resource['url'].present? && !resource['url'].starts_with?('data:image/') }
      }
      attrs[:performance_audit_log_attributes] = { logs: @logs } unless @logs.nil? || @logs.blank?
      attrs[:puppeteer_recording_attributes] = @puppeteer_recording unless @puppeteer_recording.nil? || @puppeteer_recording['s3_url'].nil?
      attrs
    end

    def formatted_page_load_resources
      (@results['page_load_resources'] || []).map do |resource| 
        {
          name: resource['name'],
          entry_type: resource['entryType'],
          fetch_start: resource['fetchStart'],
          response_end: resource['responseEnd'],
          duration: resource['duration'],
          initiator_type: resource['initiatorType']
        }
      end
    end

    def audit
      @audit ||= individual_performance_audit.audit
    end
  end
end
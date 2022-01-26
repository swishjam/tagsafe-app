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
      individual_performance_audit.update(update_attrs)
    end

    def update_attrs
      attrs = {
        dom_complete: @results['DOMComplete'],
        dom_content_loaded: @results['DOMContentLoaded'],
        dom_interactive: @results['DOMInteractive'],
        first_contentful_paint: @results['FirstContentfulPaint'],
        layout_duration: @results['LayoutDuration'],
        script_duration: @results['ScriptDuration'],
        task_duration: @results['TaskDuration'],
        tagsafe_score: calculate_tagsafe_score_for_performance_audit,
        page_trace_s3_url: @page_trace_s3_url,
        page_load_resources_attributes:  formatted_page_load_resources,
        blocked_resources_attributes: @blocked_resources
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

    def calculate_tagsafe_score_for_performance_audit
      return nil if @error
      @tagsafe_score ||= TagSafeScorer.new(
        performance_audit_calculator: @individual_performance_audit.audit.tag.domain.current_performance_audit_calculator,
        dom_complete: @results['DOMComplete'],
        dom_content_loaded: @results['DOMContentLoaded'],
        dom_interactive: @results['DOMInteractive'],
        first_contentful_paint: @results['FirstContentfulPaint'],
        layout_duration: @results['LayoutDuration'],
        script_duration: @results['ScriptDuration'],
        task_duration: @results['TaskDuration'],
        byte_size: audit.tag_version.bytes
      ).score!
    end

    def audit
      @audit ||= individual_performance_audit.audit
    end
  end
end
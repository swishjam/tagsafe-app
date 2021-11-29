module PerformanceAuditManager
  class ResultsCapturer
    attr_reader :individual_performance_audit
    def initialize(
      individual_performance_audit:, 
      results:, 
      blocked_resources:,
      logs:,
      page_load_screenshot_urls:,
      page_load_trace_json_url:,
      error:
    )
      @individual_performance_audit = individual_performance_audit
      # when lambda function times out, results are nil but is still a 200 response code
      @results = results || {}
      @logs = logs || ''
      @blocked_resources = blocked_resources || []
      @page_load_screenshot_urls = page_load_screenshot_urls || []
      @page_load_trace_json_url = page_load_trace_json_url
      @error = error
    end

    def capture_results!
      return if @individual_performance_audit.completed?
      update_individual_performance_audits_results!
      # add_page_load_screenshots_to_peformance_audit!
      add_page_load_resources_to_performance_audit!
      add_blocked_resources_to_performance_audit!
      if @error
        individual_performance_audit.error!(@error)
      else
        individual_performance_audit.completed!
      end
    end

    private

    def update_individual_performance_audits_results!
      individual_performance_audit.update(
        # dom_complete: @results['LoadEvent'],
        dom_complete: @results['DOMComplete'],
        dom_content_loaded: @results['DOMContentLoaded'],
        dom_interactive: @results['DOMInteractive'],
        first_contentful_paint: @results['FirstContentfulPaint'],
        layout_duration: @results['LayoutDuration'],
        script_duration: @results['ScriptDuration'],
        task_duration: @results['TaskDuration'],
        tagsafe_score: calculate_tagsafe_score_for_performance_audit,
        performance_audit_log_attributes: { logs: @logs },
        page_load_trace_attributes: { s3_url: @page_load_trace_json_url }
      )
    end

    # def add_page_load_screenshots_to_peformance_audit!
    #   @page_load_screenshot_urls.each_with_index do |url, i|
    #     # TODO: dont trust order of array, need to expicitly pass sequence number
    #     individual_performance_audit.page_load_screenshots.create!({
    #       s3_url: url,
    #       sequence: i
    #       # timestamp_ms: url_and_timestamp['timestamp']
    #     })
    #   end
    # end

    def add_blocked_resources_to_performance_audit!
      @blocked_resources.each do |resource|
        individual_performance_audit.blocked_resources.create!({
          url: resource['url'],
          resource_type: resource['type']
        })
      end
    end

    def add_page_load_resources_to_performance_audit!
      (@results['page_load_resources'] || []).each do |resource|
        individual_performance_audit.page_load_resources.create!({
          name: resource['name'],
          entry_type: resource['entryType'],
          initiator_type: resource['initiatorType'],
          fetch_start: resource['fetchStart'].to_f,
          response_end: resource['responseEnd'].to_f,
          duration: resource['duration'].to_f
        })
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
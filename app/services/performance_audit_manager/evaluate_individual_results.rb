module PerformanceAuditManager
  class EvaluateIndividualResults
    attr_reader :individual_performance_audit
    def initialize(
      individual_performance_audit_id:, 
      results:, 
      blocked_tag_urls:, 
      allowed_tag_urls:,
      logs:,
      aws_log_stream_name:,
      aws_request_id:,
      aws_trace_id:,
      page_load_screenshot_urls:, 
      page_load_trace_json_url:,
      error:
    )
      @results = results
      @logs = logs
      @blocked_tag_urls = blocked_tag_urls
      @allowed_tag_urls = allowed_tag_urls
      @aws_log_stream_name = aws_log_stream_name
      @aws_request_id = aws_request_id
      @aws_trace_id = aws_trace_id
      @page_load_screenshot_urls = page_load_screenshot_urls
      @page_load_trace_json_url = page_load_trace_json_url
      @error = error

      @individual_performance_audit = PerformanceAudit.includes(audit: [:tag_version, :tag]).find(individual_performance_audit_id)
    end

    def evaluate!
      unless already_processed?
        if @error
          update_individual_performance_audits_results_for_failed_audit!
          # TODO: look into dequeuing jobs that are still queued
          add_page_load_results_to_peformance_audit!
          individual_performance_audit.error!(@error)
        else
          update_individual_performance_audits_results_for_successful_audit!
          add_page_load_results_to_peformance_audit!
          individual_performance_audit.completed!
        end
      end
    end

    def already_processed?
      @individual_performance_audit.completed?
    end

    private

    def update_individual_performance_audits_results_for_successful_audit!
      individual_performance_audit.update(
        dom_complete: @results['DOMComplete'],
        dom_interactive: @results['DOMInteractive'],
        first_contentful_paint: @results['FirstContentfulPaint'],
        layout_duration: @results['LayoutDuration'],
        script_duration: @results['ScriptDuration'],
        task_duration: @results['TaskDuration'],
        tagsafe_score: calculate_tagsafe_score_for_performance_audit,
        aws_log_stream_name: @aws_log_stream_name,
        aws_request_id: @aws_request_id,
        aws_trace_id: @aws_trace_id,
        performance_audit_log_attributes: { logs: @logs },
        page_load_trace_attributes: { s3_url: @page_load_trace_json_url }
      )
    end

    def update_individual_performance_audits_results_for_failed_audit!
      individual_performance_audit.update(
        dom_complete: -1,
        dom_interactive: -1,
        first_contentful_paint: -1,
        script_duration: -1,
        layout_duration: -1,
        task_duration: -1,
        tagsafe_score: -1,
        aws_log_stream_name: @aws_log_stream_name,
        aws_request_id: @aws_request_id,
        aws_trace_id: @aws_trace_id,
        performance_audit_log_attributes: { logs: @logs },
        page_load_trace_attributes: { s3_url: @page_load_trace_json_url }
      )
    end

    def add_page_load_results_to_peformance_audit!
      @page_load_screenshot_urls.each_with_index do |url, i|
        # TODO: dont trust order of array, need to expicitly pass sequence number
        individual_performance_audit.page_load_screenshots.create!({
          s3_url: url,
          sequence: i
          # timestamp_ms: url_and_timestamp['timestamp']
        })
      end
    end

    def calculate_tagsafe_score_for_performance_audit
      @tagsafe_score ||= TagSafeScorer.new(
        dom_complete: @results['DOMComplete'],
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
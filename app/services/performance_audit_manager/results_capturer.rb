module PerformanceAuditManager
  class ResultsCapturer
    attr_reader :individual_performance_audit, :performance_audit_result

    def initialize(performance_audit_result_obj)
      @performance_audit_result = performance_audit_result_obj
      @individual_performance_audit = performance_audit_result.individual_performance_audit
    end

    def capture_results!
      return false if individual_performance_audit.completed?
      update_individual_performance_audits_results_with_results!
      if performance_audit_result.invalid?
        individual_performance_audit.error!(performance_audit_result.error)
      else
        individual_performance_audit.completed!
      end
    end

    private

    def update_individual_performance_audits_results_with_results!
      individual_performance_audit.update!(performance_audit_attrs)
      individual_performance_audit.update(performance_audit_children_attrs) unless performance_audit_children_attrs.empty?
      capture_speed_index_chart_data_and_frames_if_necessary!
      capture_long_tasks_if_necessary!
      capture_page_resources_if_necessary!
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
        page_trace_s3_url: performance_audit_result.page_trace_s3_url,
        speed_index: performance_audit_result.speed_index_results.speed_index,
        perceptual_speed_index: performance_audit_result.speed_index_results.perceptual_speed_index,
        main_thread_execution_tag_responsible_for: performance_audit_result.main_thread_results.total_main_thread_execution_ms_for_tag,
        main_thread_blocking_execution_tag_responsible_for: performance_audit_result.main_thread_results.total_main_thread_blocking_execution_ms_for_tag,
        entire_main_thread_execution_ms: performance_audit_result.main_thread_results.entire_main_thread_execution_ms,
        entire_main_thread_blocking_executions_ms: performance_audit_result.main_thread_results.entire_main_thread_blocking_executions_ms,
        ms_until_first_visual_change: performance_audit_result.speed_index_results.ms_until_first_visual_change,
        ms_until_last_visual_change: performance_audit_result.speed_index_results.ms_until_last_visual_change,
        bytes: performance_audit_result.bytes
      }
    end

    def performance_audit_children_attrs
      attrs = {}
      # attrs[:performance_audit_log_attributes] = { logs: performance_audit_result.logs } if performance_audit_result.has_logs?
      attrs[:puppeteer_recording_attributes] = performance_audit_result.puppeteer_recording.formatted_results if performance_audit_result.puppeteer_recording.included_and_valid?
      attrs
    end

    def capture_speed_index_chart_data_and_frames_if_necessary!
      if should_capture_speed_index_chart_data_and_frames?
        PerformanceAuditSpeedIndexFrame.insert_all(performance_audit_result.speed_index_results.formatted_frames(individual_performance_audit.id))
      end
    end

    def capture_long_tasks_if_necessary!
      performance_audit_result.main_thread_results.tags_long_tasks.each do |long_task_result|
        LongTask.create!(
          tag: individual_performance_audit.is_for_domain_audit? ? nil : individual_performance_audit.audit.tag,
          tag_version: individual_performance_audit.is_for_domain_audit? ? nil : individual_performance_audit.audit.tag_version,
          performance_audit: individual_performance_audit,
          task_type: long_task_result.task_type,
          start_time: long_task_result.start_time,
          end_time: long_task_result.end_time,
          duration: long_task_result.duration,
          self_time: long_task_result.self_time
        )
      end
    end

    def capture_page_resources_if_necessary!
      if should_capture_page_resources_attributes?
        PageLoadResource.insert_all(performance_audit_result.page_load_resources.formatted(individual_performance_audit.id)) if performance_audit_result.has_page_load_resources?
        BlockedResource.insert_all(performance_audit_result.blocked_resources.formatted_and_filtered(individual_performance_audit.id)) if performance_audit_result.has_blocked_resources?
      end
    end

    def should_capture_speed_index_chart_data_and_frames?
      performance_audit_result.speed_index_results.frames.any?
    end

    def should_capture_page_resources_attributes?
      !individual_performance_audit.is_for_domain_audit? && individual_performance_audit.audit.include_page_load_resources
    end
  end
end
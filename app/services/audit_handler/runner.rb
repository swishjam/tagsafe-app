module AuditHandler
  class Runner
    def initialize(
      initiated_by_container_user: nil, 
      tag: nil, 
      tag_version:,
      use_live_version_of_tag: false,
      url_to_audit:, 
      execution_reason:, 
      options: {}
    )
      @initiated_by_container_user = initiated_by_container_user
      @tag_version = tag_version
      @url_to_audit = url_to_audit
      @tag = tag || @tag_version.tag
      @execution_reason = execution_reason
      @runner_options = RunnerOptions.new(@tag, options)
    end
  
    def run!
      create_audit!
    end
  
    private
  
    def create_audit!
      Audit.create(
        initiated_by_container_user: @initiated_by_container_user,
        tag: @tag,
        tag_version: @tag_version,
        container: @tag.container,
        page_url: @url_to_audit.page_url,
        execution_reason: @execution_reason,
        primary: false,
        performance_audit_calculator: @tag.container.current_performance_audit_calculator,
        include_performance_audit: @runner_options.include_performance_audit,
        include_page_load_resources: @runner_options.include_page_load_resources,
        include_functional_tests: @runner_options.include_functional_tests,
        num_functional_tests_to_run: @runner_options.include_functional_tests ? @tag.functional_tests.enabled.count : 0,
        performance_audit_configuration_attributes: {
          batch_size: @runner_options.perf_audit_batch_size,
          completion_indicator_type: PerformanceAudit.CONFIDENCE_RANGE_COMPLETION_INDICATOR_TYPE,
          enable_screen_recording: @runner_options.perf_audit_enable_screen_recording,
          fail_when_confidence_range_not_met: @runner_options.perf_audit_fail_when_confidence_range_not_met,
          # hard coding to true for speed index and main thread task calculations
          include_page_tracing: true,
          include_filmstrip_frames: @runner_options.perf_audit_include_filmstrip_frames,
          inline_injected_script_tags: @runner_options.perf_audit_inline_injected_script_tags,
          minimum_num_sets: @runner_options.perf_audit_minimum_num_sets,
          maximum_num_sets: @runner_options.perf_audit_maximum_num_sets,
          max_failures: @runner_options.perf_audit_max_failures,
          override_initial_html_request_with_manipulated_page: @runner_options.perf_audit_override_initial_html_request_with_manipulated_page,
          required_tagsafe_score_range: @runner_options.perf_audit_required_tagsafe_score_range,
          scroll_page: @runner_options.perf_audit_scroll_page,
          strip_all_images: @runner_options.perf_audit_strip_all_images,
          throw_error_if_dom_complete_is_zero: @runner_options.perf_audit_throw_error_if_dom_complete_is_zero
        }
      )
    end
  end  
end
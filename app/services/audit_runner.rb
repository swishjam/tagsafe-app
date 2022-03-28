class AuditRunner
  def initialize(
    initiated_by_domain_user: nil, 
    tag: nil, 
    tag_version:,
    use_live_version_of_tag: false,
    url_to_audit:, 
    execution_reason:, 
    options: {}
  )
    @initiated_by_domain_user = initiated_by_domain_user
    @tag_version = tag_version
    @url_to_audit = url_to_audit
    @tag = tag || @tag_version.tag
    @execution_reason = execution_reason
    @options = options
    @options[:performance_audit_configuration] = @options[:performance_audit_configuration] || {}
  end

  def run!
    create_audit!
  end

  private

  def create_audit!
    @audit ||= Audit.create(
      initiated_by_domain_user: @initiated_by_domain_user,
      tag: @tag,
      tag_version: @tag_version,
      domain: @tag.domain,
      page_url: @url_to_audit.page_url,
      execution_reason: @execution_reason,
      primary: false,
      performance_audit_calculator: @tag.domain.current_performance_audit_calculator,
      include_performance_audit: option_value_for(:include_performance_audit, default_audit_configuration.include_performance_audit),
      include_page_load_resources: option_value_for(:include_page_load_resources, default_audit_configuration.include_page_load_resources),
      include_page_change_audit: option_value_for(:include_page_change_audit, default_audit_configuration.include_page_change_audit),
      include_functional_tests: option_value_for(:include_functional_tests, default_audit_configuration.include_functional_tests),
      num_functional_tests_to_run: option_value_for(:include_functional_tests, true) ? @tag.functional_tests.enabled.count : 0,
      performance_audit_configuration_attributes: {
        batch_size: performance_audit_configuration_for(:batch_size, default_audit_configuration.perf_audit_batch_size),
        completion_indicator_type: performance_audit_completion_indicator_type,
        enable_screen_recording: performance_audit_configuration_for(:enable_screen_recording, default_audit_configuration.perf_audit_enable_screen_recording),
        fail_when_confidence_range_not_met: performance_audit_configuration_for(:fail_when_confidence_range_not_met, default_audit_configuration.perf_audit_fail_when_confidence_range_not_met),
        # include_page_tracing: performance_audit_configuration_for(:include_page_tracing, default_audit_configuration.perf_audit_include_page_tracing),
        # setting `include_page_tracing` as the `enable_screen_recording` arg for now because of the bug
        # that the screen recording is blank unless this is true, and we are not using the page_trace for anything
        # else at the moment
        include_page_tracing: performance_audit_configuration_for(:enable_screen_recording, default_audit_configuration.perf_audit_enable_screen_recording),
        inline_injected_script_tags: performance_audit_configuration_for(:inline_injected_script_tags, default_audit_configuration.perf_audit_inline_injected_script_tags),
        minimum_num_sets: performance_audit_configuration_for(:minimum_num_sets, default_audit_configuration.perf_audit_minimum_num_sets),
        maximum_num_sets: performance_audit_configuration_for(:minimum_num_sets, default_audit_configuration.perf_audit_maximum_num_sets),
        max_failures: performance_audit_configuration_for(:max_failures, default_audit_configuration.perf_audit_max_failures),
        num_performance_audits_to_run: performance_audit_completion_indicator_type == PerformanceAudit.CONFIDENCE_RANGE_COMPLETION_INDICATOR_TYPE ? nil : performance_audit_configuration_for(:num_performance_audits_to_run, default_audit_configuration.num_perf_audits_to_run),
        override_initial_html_request_with_manipulated_page: performance_audit_configuration_for(:override_initial_html_request_with_manipulated_page, default_audit_configuration.perf_audit_override_initial_html_request_with_manipulated_page),
        required_tagsafe_score_range: performance_audit_completion_indicator_type == PerformanceAudit.CONFIDENCE_RANGE_COMPLETION_INDICATOR_TYPE ? performance_audit_configuration_for(:required_tagsafe_score_range, default_audit_configuration.perf_audit_required_tagsafe_score_range) : nil,
        scroll_page: performance_audit_configuration_for(:scroll_page, default_audit_configuration.perf_audit_scroll_page),
        strip_all_images: performance_audit_configuration_for(:strip_all_images, default_audit_configuration.perf_audit_strip_all_images),
        throw_error_if_dom_complete_is_zero: performance_audit_configuration_for(:throw_error_if_dom_complete_is_zero, default_audit_configuration.perf_audit_throw_error_if_dom_complete_is_zero)
      }
    )
  end

  def default_audit_configuration
    @tag.default_audit_configuration || @tag.domain.default_audit_configuration
  end

  def option_value_for(option, default_value)
    @options[option] != nil ? @options[option] : default_value
  end

  def performance_audit_completion_indicator_type
    performance_audit_configuration_for(:completion_indicator_type, default_audit_configuration.perf_audit_completion_indicator_type)
  end

  def performance_audit_configuration_for(config, default_value)
    @options[:performance_audit_configuration][config] != nil ? @options[:performance_audit_configuration][config] : default_value
  end
end

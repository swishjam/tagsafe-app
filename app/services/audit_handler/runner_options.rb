module AuditHandler
  class RunnerOptions
    class InvalidOptionError < StandardError; end;
    VALID_ROOT_OPTS = %i[
      include_performance_audit 
      include_page_load_resources 
      include_functional_tests 
      include_functional_tests 
      performance_audit_configuration
    ]
    VALID_PERF_AUDIT_OPTS = %i[
      batch_size 
      enable_screen_recording 
      fail_when_confidence_range_not_met 
      include_page_tracing
      include_filmstrip_frames
      inline_injected_script_tags
      minimum_num_sets
      maximum_num_sets
      max_failures
      override_initial_html_request_with_manipulated_page
      required_tagsafe_score_range
      scroll_page
      strip_all_images
      throw_error_if_dom_complete_is_zero
    ]

    def initialize(tag, provided_opts)
      @tag = tag
      @provided_opts = provided_opts.with_indifferent_access
      ensure_options_are_valid!
    end

    def include_performance_audit 
      option_value_for(:include_performance_audit, default_configuration.include_performance_audit)
    end

    def include_page_load_resources 
      option_value_for(:include_page_load_resources, default_configuration.include_page_load_resources)
    end

    def include_functional_tests 
      option_value_for(:include_functional_tests, default_configuration.include_functional_tests)
    end

    def perf_audit_batch_size
      performance_audit_configuration_for(:batch_size, default_configuration.perf_audit_batch_size)
    end

    def perf_audit_enable_screen_recording
      performance_audit_configuration_for(:enable_screen_recording, default_configuration.perf_audit_enable_screen_recording)
    end

    def perf_audit_fail_when_confidence_range_not_met
      performance_audit_configuration_for(:fail_when_confidence_range_not_met, default_configuration.perf_audit_fail_when_confidence_range_not_met)
    end

    def perf_audit_include_filmstrip_frames
      performance_audit_configuration_for(:include_filmstrip_frames, default_configuration.perf_audit_include_filmstrip_frames)
    end

    def perf_audit_inline_injected_script_tags
      performance_audit_configuration_for(:inline_injected_script_tags, default_configuration.perf_audit_inline_injected_script_tags)
    end

    def perf_audit_minimum_num_sets
      performance_audit_configuration_for(:minimum_num_sets, default_configuration.perf_audit_minimum_num_sets)
    end

    def perf_audit_maximum_num_sets
      performance_audit_configuration_for(:minimum_num_sets, default_configuration.perf_audit_maximum_num_sets)
    end

    def perf_audit_max_failures
      performance_audit_configuration_for(:max_failures, default_configuration.perf_audit_max_failures)
    end

    def perf_audit_override_initial_html_request_with_manipulated_page
      performance_audit_configuration_for(:override_initial_html_request_with_manipulated_page, default_configuration.perf_audit_override_initial_html_request_with_manipulated_page)
    end

    def perf_audit_required_tagsafe_score_range
      performance_audit_configuration_for(:required_tagsafe_score_range, default_configuration.perf_audit_required_tagsafe_score_range)
    end

    def perf_audit_scroll_page
      performance_audit_configuration_for(:scroll_page, default_configuration.perf_audit_scroll_page)
    end

    def perf_audit_strip_all_images
      performance_audit_configuration_for(:strip_all_images, default_configuration.perf_audit_strip_all_images)
    end

    def perf_audit_throw_error_if_dom_complete_is_zero
      performance_audit_configuration_for(:throw_error_if_dom_complete_is_zero, default_configuration.perf_audit_throw_error_if_dom_complete_is_zero)
    end

    private

    def ensure_options_are_valid!
      @provided_opts.keys.each do |root_key|
        raise InvalidOptionError, "Unrecognized AuditHandler::RunnerOptions option: `#{root_key}`, valid options are #{VALID_ROOT_OPTS.join(', ')}" unless VALID_ROOT_OPTS.include?(root_key.to_sym)
      end
      (@provided_opts[:performance_audit_configuration] || {}).keys.each do |perf_audit_key|
        raise InvalidOptionError, "Unrecognized AuditHandler::RunnerOptions performance audit option: `#{perf_audit_key}`, valid options are #{VALID_PERF_AUDIT_OPTS.join(', ')}" unless VALID_PERF_AUDIT_OPTS.include?(perf_audit_key.to_sym)
      end
    end

    def default_configuration
      @configuration ||= @tag.tag_or_container_configuration
    end
  
    def option_value_for(option, default_value)
      @provided_opts[option] != nil ? @provided_opts[option] : default_value
    end
      
    def performance_audit_configuration_for(config, default_value)
      (@provided_opts[:performance_audit_configuration] || {})[config] != nil ? (@provided_opts[:performance_audit_configuration] || {})[config] : default_value
    end
  end
end
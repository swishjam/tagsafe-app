class AuditRunner
  def initialize(audit:, tag_version:, url_to_audit_id:, execution_reason:, options: {})
    @tag_version = tag_version
    @url_to_audit_id = url_to_audit_id
    @tag = @tag_version.tag
    @execution_reason = execution_reason
    @options = options
    @options[:performance_audit_configuration] = @options[:performance_audit_configuration] || {}

    @audit = audit || create_audit
  end

  def run!
    if audit.valid?
      audit.update(enqueued_suite_at: DateTime.now)
      enqueue_performance_audit!
      enqueue_functional_tests!
      enqueue_page_change_audit!
    end
    audit
  end

  private

  def enqueue_performance_audit!
    if audit.include_performance_audit
      # all performance options should now be persisted in the PerformanceAuditConfiguration
      # AuditRunnerJobs::RunPerformanceAudit.perform_later(audit, @options[:performance_audit_options] || {})
      AuditRunnerJobs::RunPerformanceAudit.perform_later(audit)
    end
  end

  def enqueue_page_change_audit!
    if audit.include_page_change_audit
      # AuditRunnerJobs::RunPageChangeAudit.perform_later(audit, @options[:page_change_audit_options] || {})
      AuditRunnerJobs::RunPageChangeAudit.perform_later(audit)
    end
  end

  def enqueue_functional_tests!
    if audit.include_functional_tests
      # AuditRunnerJobs::RunFunctionalTestSuiteForAudit.perform_later(audit, @options[:functional_tests_options] || {})
      AuditRunnerJobs::RunFunctionalTestSuiteForAudit.perform_later(audit)
    end
  end

  def audit
    @audit ||= Audit.create(
      tag: @tag,
      tag_version: @tag_version,
      page_url: url_to_audit.page_url,
      execution_reason: @execution_reason,
      primary: false,
      performance_audit_calculator: @tag.domain.current_performance_audit_calculator,
      include_performance_audit: option_value_for(:include_performance_audit, true),
      include_page_load_resources: option_value_for(:include_page_load_resources, true),
      include_page_change_audit: option_value_for(:include_page_change_audit, true),
      include_functional_tests: option_value_for(:include_functional_tests, true),
      num_functional_tests_to_run: option_value_for(:include_functional_tests, true) ? @tag.functional_tests.enabled.count : 0,
      performance_audit_configuration_attributes: {
        performance_audit_iterations: tag_preferences.performance_audit_iterations,
        strip_all_images: performance_audit_configuration_for(:strip_all_images, true),
        include_page_tracing: performance_audit_configuration_for(:include_page_tracing, true),
        throw_error_if_dom_complete_is_zero: performance_audit_configuration_for(:throw_error_if_dom_complete_is_zero, true),
        inline_injected_script_tags: performance_audit_configuration_for(:inline_injected_script_tags, false),
        scroll_page: performance_audit_configuration_for(:scroll_page, false),
        enable_screen_recording: performance_audit_configuration_for(:enable_screen_recording, true),
        override_initial_html_request_with_manipulated_page: performance_audit_configuration_for(:override_initial_html_request_with_manipulated_page, Flag.flag_is_true(@tag.domain, 'override_initial_html_request_with_manipulated_page'))
      }
    )
  end
  alias create_audit audit
  
  def tag_preferences
    @tag_preferences ||= @tag.tag_preferences
  end

  def url_to_audit
    @url_to_audit ||= UrlToAudit.find(@url_to_audit_id)
  end

  def option_value_for(option, default_value)
    @options[option] != nil ? @options[option] : default_value
  end

  def performance_audit_configuration_for(config, default_value)
    @options[:performance_audit_configuration][config] != nil ? @options[:performance_audit_configuration][config] : default_value
  end
end

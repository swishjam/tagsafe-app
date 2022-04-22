module StepFunctionInvoker
  class PerformanceAuditer < Base
    self.step_function_arn = "arn:aws:states:us-east-1:407342930315:stateMachine:#{Rails.env}-run-performance-audit"
    self.results_consumer_klass = StepFunctionResponses::PerformanceAuditResult

    def initialize(audit:, performance_audit_klass:, batch_identifier:, options: {})
      @audit = audit
      @performance_audit_klass = performance_audit_klass
      @receiver_job_queue = @audit.initiated_by_user? ? TagsafeQueue.CRITICAL : nil
    end

    def individual_performance_audit
      @individual_performance_audit ||= @performance_audit_klass.create!(audit: @audit, batch_identifier: @batch_identifier)
    end
    alias executed_step_function_parent individual_performance_audit
  
    private
  
    def request_payload
      {
        individual_performance_audit_id: individual_performance_audit.id,
        tag_url_being_audited: @audit.run_on_tagsafe_tag_version? ? tag_version.js_file_url : tag.full_url,
        page_url_to_perform_audit_on: @audit.page_url.full_url,
        first_party_request_url: tag.domain.parsed_domain_url,
        third_party_tag_urls_and_rules_to_inject: script_injection_rules,
        third_party_tag_url_patterns_to_allow: third_party_tag_url_patterns_to_allow,
        cached_responses_s3_key: @audit.performance_audit_configuration.cached_responses_s3_key,
        options: {
          override_initial_html_request_with_manipulated_page: @audit.performance_audit_configuration.override_initial_html_request_with_manipulated_page.to_s,
          # puppeteer_page_wait_until: 'networkidle2',
          puppeteer_page_timeout_ms: 0,
          enable_screen_recording: @audit.performance_audit_configuration.enable_screen_recording.to_s,
          throw_error_if_dom_complete_is_zero: @audit.performance_audit_configuration.throw_error_if_dom_complete_is_zero.to_s,
          include_page_load_resources: true, # consumer will decide whether to capture them or not
          include_page_tracing: @audit.performance_audit_configuration.include_page_tracing.to_s,
          inline_injected_script_tags: @audit.performance_audit_configuration.inline_injected_script_tags.to_s,
          scroll_page: @audit.performance_audit_configuration.scroll_page.to_s,
          strip_all_images: @audit.performance_audit_configuration.strip_all_images.to_s,
          strip_all_css: false.to_s
        }
      }
    end

    def tag
      @tag ||= @audit.tag
    end

    def tag_version
      @tag_version ||= @audit.tag_version
    end

    def script_injection_rules
      return [] unless individual_performance_audit.is_a?(IndividualPerformanceAuditWithTag)
      js_file_url = @audit.run_on_tagsafe_tag_version? ? tag_version.js_file_url : tag.full_url
      [{ url: js_file_url, load_type: tag.load_type || 'async' }]
    end

    def third_party_tag_url_patterns_to_allow
      tag.domain.non_third_party_url_patterns.collect(&:pattern)
    end
  end
end
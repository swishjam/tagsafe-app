module LambdaModerator
  class PerformanceAuditer < Base
    lambda_service 'performance-auditer'
    lambda_function 'runPerformanceAudit'

    def initialize(audit:, perform_audit_with_tag:, options: {})
      @audit = audit
      @perform_audit_with_tag = perform_audit_with_tag
      @executed_lambda_function_parent = individual_performance_audit
    end

    def individual_performance_audit
      @individual_performance_audit ||= IndividualPerformanceAudit.create!(
        audit: @audit,
        audit_performed_with_tag: @perform_audit_with_tag,
        # enqueued_at: Time.now
      )
    end
  
    private
  
    def request_payload
      {
        page_url_to_perform_audit_on: @audit.page_url.full_url,
        first_party_request_url: tag.domain.parsed_domain_url,
        third_party_tag_urls_and_rules_to_inject: script_injection_rules,
        third_party_tag_url_patterns_to_allow: tag.domain.non_third_party_url_patterns.collect(&:pattern),
        cached_responses_s3_key: @audit.performance_audit_configuration.cached_responses_s3_key,
        options: {
          override_initial_html_request_with_manipulated_page: @audit.performance_audit_configuration.override_initial_html_request_with_manipulated_page.to_s,
          # puppeteer_page_wait_until: 'networkidle2',
          puppeteer_page_timeout_ms: 0,
          enable_screen_recording: @audit.performance_audit_configuration.enable_screen_recording.to_s,
          throw_error_if_dom_complete_is_zero: @audit.performance_audit_configuration.throw_error_if_dom_complete_is_zero.to_s,
          include_page_load_resources: @audit.include_page_load_resources.to_s,
          include_page_tracing: @audit.performance_audit_configuration.include_page_tracing.to_s,
          inline_injected_script_tags: @audit.performance_audit_configuration.inline_injected_script_tags.to_s,
          scroll_page: @audit.performance_audit_configuration.scroll_page.to_s,
          strip_all_images: @audit.performance_audit_configuration.strip_all_images.to_s,
          strip_all_css: false.to_s
        }
      }
    end

    def tag
      @tag ||= tag_version.tag
    end

    def tag_version
      @tag_version ||= @audit.tag_version
    end

    def script_injection_rules
      return [] unless @perform_audit_with_tag
      [{ url:  tag_version.js_file_url, load_type: 'async' }]
    end

    def required_payload_arguments
      %i[page_url_to_perform_audit_on third_party_tag_urls_and_rules_to_inject first_party_request_url options]
    end
  end
end
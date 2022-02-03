module LambdaModerator
  class PerformanceAuditer < Base
    lambda_service 'performance-auditer'
    lambda_function 'runPerformanceAudit'

    def initialize(type:, audit:, tag_version:, options: {})
      @type = type
      @audit = audit
      @tag_version = tag_version
      @executed_lambda_function_parent = individual_performance_audit
    end

    def individual_performance_audit
      @individual_performance_audit ||= individual_performance_audit_klass.create(audit: @audit, enqueued_at: Time.now)
    end
  
    private

    def individual_performance_audit_klass
      @type == :with_tag ? IndividualPerformanceAuditWithTag : IndividualPerformanceAuditWithoutTag
    end
  
    def request_payload
      {
        page_url_to_perform_audit_on: @audit.page_url.full_url,
        first_party_request_url: tag.domain.parsed_domain_url,
        third_party_tag_urls_and_rules_to_inject: script_injection_rules,
        cached_responses_s3_key: @audit.performance_audit_cached_responses_s3_url ? TagsafeS3.url_to_key(@audit.performance_audit_cached_responses_s3_url) : nil,
        third_party_tag_url_patterns_to_allow: tag.domain.non_third_party_url_patterns.collect(&:pattern),
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
      @tag ||= @tag_version.tag
    end

    def script_injection_rules
      case @type
      when :with_tag
        # TODO: make load_type specific to the type of tag
        [{ url:  @tag_version.js_file_url, load_type: 'async' }]
      when :without_tag
        []
      when nil
        raise PerformanceAuditError::InvalidType, "PerformanceAuditer called without a `type`, must pass a type of either `:with_tag` or `:without_tag`"
      else
        raise PerformanceAuditError::InvalidType, "PerformanceAuditer called with an invalid type of #{@type}, valid values are :with_tag or :without_tag"
      end
    end

    def required_payload_arguments
      %i[page_url_to_perform_audit_on third_party_tag_urls_and_rules_to_inject first_party_request_url options]
    end
  end
end
module LambdaModerator
  class PerformanceAuditer < Base
    lambda_service 'performance-auditer'
    lambda_function 'runPerformanceAudit'

    def initialize(type:, audit:, tag_version:, options: {})
      @type = type
      @audit = audit
      @tag_version = tag_version
      @executed_lambda_function_parent = individual_performance_audit
      
      @include_performance_trace = option_for(options, 'include_performance_trace').to_s
      @include_page_load_resources = option_for(options, 'include_page_load_resources').to_s
      @inline_injected_script_tags = option_for(options, 'inline_injected_script_tags').to_s
      @strip_all_css_in_performance_audits = option_for(options, 'strip_all_css_in_performance_audits').to_s
      @strip_all_images_in_performance_audits = option_for(options, 'strip_all_images_in_performance_audits').to_s
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
        page_url_to_perform_audit_on: @audit.audited_url.audit_url,
        first_party_request_url: tag.domain.parsed_domain_url,
        third_party_tag_urls_and_rules_to_inject: script_injection_rules,
        third_party_tag_url_patterns_to_allow: tag.domain.non_third_party_url_patterns.collect(&:pattern),
        options: {
          puppeteer_page_wait_until: 'networkidle2',
          puppeteer_page_timeout_ms: 0,
          enable_page_load_tracing: @include_performance_trace,
          include_page_load_resources: @include_page_load_resources,
          inline_injected_script_tags: @inline_injected_script_tags,
          strip_all_images: @strip_all_images_in_performance_audits,
          strip_all_css: @strip_all_css_in_performance_audits
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
        [{ url:  @tag_version.hosted_tagsafe_instrumented_js_file_url, load_type: 'async' }]
      when :without_tag
        []
      when nil
        raise PerformanceAuditError::InvalidType, "PerformanceAuditer called without a `type`, must pass a type of either `:with_tag` or `:without_tag`"
      else
        raise PerformanceAuditError::InvalidType, "PerformanceAuditer called with an invalid type of #{@type}, valid values are :with_tag or :without_tag"
      end
    end

    def option_for(options, flag_slug)
      !options[flag_slug.to_sym].nil? ? options[flag_slug.to_sym] : Flag.flag_is_true_for_objects(tag, tag.domain, tag.domain.organization, slug: flag_slug.to_s)
    end

    def required_payload_arguments
      %i[page_url_to_perform_audit_on third_party_tag_urls_and_rules_to_inject first_party_request_url options]
    end
  end
end
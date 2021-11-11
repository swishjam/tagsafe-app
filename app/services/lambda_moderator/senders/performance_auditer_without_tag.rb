module LambdaModerator
  module Senders
    class PerformanceAuditerWithoutTag < Base
      lambda_service 'performance-auditer'
      lambda_function 'runPerformanceAudit'

      def initialize(audit:, tag_version:, enable_tracing: false, include_page_load_resources: true, inline_injected_tags: true)
        @audit = audit
        @tag_version = tag_version
        @page_load_tracing = enable_tracing
        @executed_lambda_function_parent = individual_performance_audit
        @include_page_load_resources = include_page_load_resources
        @inline_injected_tags = inline_injected_tags
      end

      def individual_performance_audit
        @individual_performance_audit ||= IndividualPerformanceAuditWithoutTag.create(audit: @audit, enqueued_at: Time.now)
      end
    
      private
    
      def request_payload
        {
          audit_id: @audit.id,
          individual_performance_audit_id: individual_performance_audit.id,
          page_url_to_perform_audit_on: @audit.audited_url.audit_url,
          first_party_request_url: tag.domain.parsed_domain_url,
          third_party_tag_urls_and_rules_to_inject: [],
          puppeteer_page_wait_until: 'networkidle2',
          puppeteer_page_timeout_ms: 0,
          enable_page_load_tracing: @page_load_tracing,
          include_page_load_resources: @include_page_load_resources,
          inline_injected_script_tags: @inline_injected_tags
        }
      end

      def tag
        @tag ||= @tag_version.tag
      end
      
      def required_payload_arguments
        %i[audit_id individual_performance_audit_id page_url_to_perform_audit_on third_party_tag_urls_and_rules_to_inject first_party_request_url]
      end
    end
  end
end
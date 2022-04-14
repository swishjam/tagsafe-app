module LambdaFunctionInvoker
  class DomainAuditer < Base
    self.lambda_service = 'performance-audits'
    self.lambda_function = 'run-performance-audit'
    self.results_consumer_klass = LambdaEventResponses::DomainAuditResult
    self.results_consumer_job_queue = TagsafeQueue.CRITICAL

    def initialize(domain_audit, individual_performance_audit_klass)
      @domain_audit = domain_audit
      @individual_performance_audit_klass = individual_performance_audit_klass
    end

    def individual_performance_audit
      @individual_performance_audit ||= @individual_performance_audit_klass.create(domain_audit: @domain_audit)
    end
    alias executed_lambda_function_parent individual_performance_audit

    def request_payload
      {
        domain_audit_id: @domain_audit.id,
        individual_performance_audit_id: individual_performance_audit.id,
        page_url_to_perform_audit_on: @domain_audit.page_url.full_url,
        first_party_request_url: @domain_audit.domain.parsed_domain_url,
        third_party_tag_urls_and_rules_to_inject: [],
        third_party_tag_url_patterns_to_allow: [],
        allow_all_third_party_tags: run_performance_audit_with_all_tags_enabled?,
        options: {
          enable_screen_recording: true,
          strip_all_images: true,
          throw_error_if_dom_complete_is_zero: true,
          include_page_load_resources: false,
          include_page_tracing: true,
        }
      }
    end

    def run_performance_audit_with_all_tags_enabled?
      individual_performance_audit.is_a?(IndividualPerformanceAuditWithTag)
    end
  end
end
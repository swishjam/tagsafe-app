module GeppettoModerator
  module LambdaSenders
    class PerformanceAuditerWithoutTag < Base
      lambda_service 'performance-auditer'
      lambda_function 'runPerformanceAudit'

      def initialize(audit:, tag_version:)
        @audit = audit
        @tag_version = tag_version
      end
    
      private
    
      def request_payload
        {
          audit_id: @audit.id,
          individual_performance_audit_id: individual_performance_audit.id,
          page_url_to_perform_audit_on: tag.tag_preferences.page_url_to_perform_audit_on,
          third_party_tag_url_patterns_to_block: [tag.url_based_on_preferences],
          third_party_tags_to_overwrite: [],
          puppeteer_page_wait_until: 'networkidle2',
          puppeteer_page_timeout_ms: 0
        }
      end

      def individual_performance_audit
        @individual_performance_audit ||= IndividualPerformanceAuditWithoutTag.create(audit: @audit, enqueued_at: Time.now)
      end

      def tag
        @tag ||= @tag_version.tag
      end
      
      def required_payload_arguments
        %i[audit_id individual_performance_audit_id page_url_to_perform_audit_on third_party_tag_url_patterns_to_block third_party_tag_url_patterns_to_block]
      end
    end
  end
end
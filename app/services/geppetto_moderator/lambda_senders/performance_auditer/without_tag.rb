module GeppettoModerator
  module LambdaSenders
    module PerformanceAuditer
      class WithoutTag
        lambda_service_name ''
        lambda_function_name


        def initialize(audit:, tag_version:, num_attempts:)
          @endpoint = '/api/run_performance_audit' 
          @audit = audit
          @tag_version = tag_version
          @num_attempts = num_attempts
        end
      
        private
      
        def request_body
          {
            audit_id: @audit.id,
            page_url_to_perform_audit_on: @tag.tag_preferences.url_to_audit,
            num_attempts: @num_attempts,
            # auditing_tag_url: @tag.url_based_on_preferences,
            third_party_tags_to_block: [@tag.url_based_on_preferences],
            third_party_tag_url_patterns_to_allow: allowed_third_party_tag_patterns,
            third_party_tags_to_overwrite: [{ request_url: @tag.full_url, overwrite_url: @tag_version.google_cloud_js_file_url }],
            # disable_third_party_tags: disable_all_third_party_tags
          }
        end
      
        def allowed_third_party_tag_patterns
          @tag.domain.allowed_third_party_tag_urls.concat(
            @tag.tag_allowed_performance_audit_third_party_urls.collect(&:url_pattern)
          ).concat(
            @tag.domain.non_third_party_url_patterns.collect(&:pattern)
          )
        end
      
        # def disable_all_third_party_tags
        #   @tag.domain.disable_all_third_party_tags_during_audits
        # end
      end
    end
  end
end
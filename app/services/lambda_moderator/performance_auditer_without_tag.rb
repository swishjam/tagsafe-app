# module LambdaModerator
#   module Senders
#     class PerformanceAuditerWithoutTag < Base
#       lambda_service 'performance-auditer'
#       lambda_function 'runPerformanceAudit'

#       def initialize(audit:, tag_version:)
#         @audit = audit
#         @tag_version = tag_version
#         @executed_lambda_function_parent = individual_performance_audit
#       end

#       def individual_performance_audit
#         @individual_performance_audit ||= IndividualPerformanceAuditWithoutTag.create(audit: @audit, enqueued_at: Time.now)
#       end
    
#       private
    
#       def request_payload
#         {
#           # audit_id: @audit.id,
#           # individual_performance_audit_id: individual_performance_audit.id,
#           page_url_to_perform_audit_on: @audit.audited_url.audit_url,
#           first_party_request_url: tag.domain.parsed_domain_url,
#           third_party_tag_urls_and_rules_to_inject: [],
#           third_party_tag_url_patterns_to_allow: tag.domain.non_third_party_url_patterns.collect(&:pattern),
#           options: {
#             puppeteer_page_wait_until: 'networkidle2',
#             puppeteer_page_timeout_ms: 0,
#             enable_page_load_tracing: enable_tracing.to_s,
#             include_page_load_resources: include_page_load_resources.to_s,
#             inline_injected_script_tags: inline_injected_script_tags.to_s,
#             strip_all_images: 'true',
#             strip_all_css: 'true'
#           }
#         }
#       end

#       def tag
#         @tag ||= @tag_version.tag
#       end

#       def include_page_load_resources
#         Flag.flag_is_true_for_objects(@tag, @tag.domain, @tag.domain.organization, slug: 'include_page_load_resources')
#       end
    
#       def enable_tracing
#         Flag.flag_is_true_for_objects(@tag, @tag.domain, @tag.domain.organization, slug: 'include_performance_trace')
#       end
    
#       def inline_injected_script_tags
#         Flag.flag_is_true_for_objects(@tag, @tag.domain, @tag.domain.organization, slug: 'inline_injected_script_tags')
#       end
      
#       def required_payload_arguments
#         %i[page_url_to_perform_audit_on third_party_tag_urls_and_rules_to_inject first_party_request_url]
#       end
#     end
#   end
# end
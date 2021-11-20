# module LambdaModerator
#   module Senders
#     class PerformanceAuditerWithTag < Base
#       lambda_service 'performance-auditer'
#       lambda_function 'runPerformanceAudit'
 
#       def initialize(audit:, tag_version:, options: {})
#         @audit = audit
#         @tag_version = tag_version
#         @executed_lambda_function_parent = individual_performance_audit
        
#         @include_performance_trace = option_for(options, 'include_performance_trace').to_s
#         @include_page_load_resources = option_for(options, 'include_page_load_resources').to_s
#         @inline_injected_script_tags = option_for(options, 'inline_injected_script_tags').to_s
#         @strip_all_css_in_performance_audits = option_for(options, 'strip_all_css_in_performance_audits').to_s
#         @strip_all_images_in_performance_audits = option_for(options, 'strip_all_images_in_performance_audits').to_s
#       end

#       def individual_performance_audit
#         @individual_performance_audit ||= IndividualPerformanceAuditWithTag.create(audit: @audit, enqueued_at: Time.now)
#       end
    
#       private
    
#       def request_payload
#         {
#           page_url_to_perform_audit_on: @audit.audited_url.audit_url,
#           first_party_request_url: tag.domain.parsed_domain_url,
#           third_party_tag_urls_and_rules_to_inject: [{ url:  @tag_version.hosted_tagsafe_instrumented_js_file_url, load_type: 'async' }],
#           third_party_tag_url_patterns_to_allow: tag.domain.non_third_party_url_patterns.collect(&:pattern),
#           options: {
#             puppeteer_page_wait_until: 'networkidle2',
#             puppeteer_page_timeout_ms: 0,
#             enable_page_load_tracing: @include_performance_trace,
#             include_page_load_resources: @include_page_load_resources,
#             inline_injected_script_tags: @inline_injected_script_tags,
#             strip_all_images: @strip_all_images_in_performance_audits,
#             strip_all_css: @strip_all_css_in_performance_audits
#           }
#         }
#       end

#       def tag
#         @tag ||= @tag_version.tag
#       end

#       def option_for(options, flag_slug)
#         defined? options[flag_slug.to_sym] ? options[flag_slug.to_sym] : Flag.flag_is_true_for_objects(@tag, @tag.domain, @tag.domain.organization, slug: flag_slug)
#       end

#       def required_payload_arguments
#         %i[page_url_to_perform_audit_on third_party_tag_urls_and_rules_to_inject first_party_request_url]
#       end
#     end
#   end
# end
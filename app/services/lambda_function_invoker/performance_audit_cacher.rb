# module LambdaFunctionInvoker
#   class PerformanceAuditCacher < Base
#     lambda_service = 'performance-audits'
#     lambda_function = 'generate-cache'

#     def initialize(audit:, tag_version:, options: {})
#       @audit = audit
#       @tag_version = tag_version
#       # TODO: the audit probably shouldn't be the parent of the executed_lambda_function...
#       @executed_lambda_function_parent = audit
      
#       @include_page_load_resources = audit.include_page_load_resources.to_s
#       @inline_injected_script_tags = option_or_flag_for(options, 'inline_injected_script_tags')
#       @strip_all_css_in_performance_audits = option_or_flag_for(options, 'strip_all_css_in_performance_audits')
#       @strip_all_images_in_performance_audits = option_or_flag_for(options, 'strip_all_images_in_performance_audits')
#       @throw_error_if_dom_complete_is_zero = option_or_flag_for(options, 'performance_audit_throw_error_if_dom_complete_is_zero')
#     end
  
#     private
  
#     def request_payload
#       {
#         page_url_to_perform_audit_on: @audit.page_url.full_url,
#         first_party_request_url: tag.domain.parsed_domain_url,
#         third_party_tag_urls_and_rules_to_inject: script_injection_rules,
#         third_party_tag_url_patterns_to_allow: tag.domain.non_third_party_url_patterns.collect(&:pattern),
#         options: {
#           puppeteer_page_wait_until: 'networkidle2',
#           puppeteer_page_timeout_ms: 0,
#           throw_error_if_dom_complete_is_zero: @throw_error_if_dom_complete_is_zero,
#           include_page_load_resources: @include_page_load_resources,
#           inline_injected_script_tags: @inline_injected_script_tags,
#           strip_all_images: @strip_all_images_in_performance_audits,
#           strip_all_css: @strip_all_css_in_performance_audits
#         }
#       }
#     end

#     def tag
#       @tag ||= @tag_version.tag
#     end

#     def script_injection_rules
#       # TODO: make load_type specific to the type of tag
#       [{ url:  @tag_version.js_file_url, load_type: 'async' }]
#     end

#     def option_or_flag_for(options, flag_slug)
#       (!options[flag_slug.to_sym].nil? ? options[flag_slug.to_sym] : Flag.flag_is_true_for_objects(tag, tag.domain, slug: flag_slug.to_s)).to_s
#     end

#     def required_payload_arguments
#       %i[page_url_to_perform_audit_on third_party_tag_urls_and_rules_to_inject first_party_request_url options]
#     end
#   end
# end
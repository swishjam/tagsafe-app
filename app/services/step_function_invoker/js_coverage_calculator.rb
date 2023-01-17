module StepFunctionInvoker
  class JsCoverageCalculator < Base
    self.step_function_name = 'calculate-js-coverage'
    self.results_consumer_klass = StepFunctionResponses::JsCoverageResult

    def initialize(js_usage_audit_component, options: {})
      @js_usage_audit_component = js_usage_audit_component
      @audit = js_usage_audit_component.audit
      @page_url = @audit.page_url
      @tag = @audit.tag
      @disable_tagsafe_js_on_page_url = options[:disable_tagsafe_js_on_page_url] == nil ? true : options[:disable_tagsafe_js_on_page_url]
      @receiver_job_queue = TagsafeQueue.CRITICAL
    end

    def executed_step_function_parent
      @js_usage_audit_component
    end
  
    private
  
    def request_payload
      { 
        tag_url_to_inject: @audit.tag_version.present? ? @audit.tag_version.s3_url : @tag.full_url, 
        tag_to_inject_load_strategy: @tag.configured_load_strategy_based_on_preferences,
        tag_url_patterns_to_block: @tag.url_based_on_preferences, 
        page_url: stringified_page_url, 
        coverage_multiplier: 1.5,
        js_usage_audit_component_uid: @js_usage_audit_component.uid
      }
    end

    def should_use_tagsafe_hosted_tag_version?
      @tag.is_tagsafe_hosted? && @audit.tag_version.present?
    end

    def stringified_page_url
      "#{@page_url.url_without_query_params}#{@disable_tagsafe_js_on_page_url ? '?tagsafe-disable-tag-re-route=true' : ''}"
    end
  end
end
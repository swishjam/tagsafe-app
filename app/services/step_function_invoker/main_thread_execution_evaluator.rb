module StepFunctionInvoker
  class MainThreadExecutionEvaluator < Base
    self.step_function_name = 'evaluate-main-thread-execution'
    self.results_consumer_klass = StepFunctionResponses::MainThreadExecutionEvaluationResult

    def initialize(main_thread_execution_audit_component, options: {})
      @main_thread_execution_audit_component = main_thread_execution_audit_component
      @audit = main_thread_execution_audit_component.audit
      @page_url = @audit.page_url
      @tag = @audit.tag
      @disable_tagsafe_js_on_page_url = options[:disable_tagsafe_js_on_page_url] == nil ? true : options[:disable_tagsafe_js_on_page_url]
      @receiver_job_queue = TagsafeQueue.CRITICAL
    end

    def executed_step_function_parent
      @main_thread_execution_audit_component
    end
  
    private
  
    def request_payload
      { 
        page_url: stringified_page_url, 
        tag_url: @audit.tag_version.present? ? @audit.tag_version.s3_url : @tag.full_url,
        tag_url_patterns_to_block: [@tag.hostname_and_path],
        tag_url_loading_strategy: @tag.configured_load_strategy_based_on_preferences,
        main_thread_blocking_multiplier: 0.2,
        total_main_thread_execution_multiplier: 0.1,
        main_thread_execution_audit_component_uid: @main_thread_execution_audit_component.uid,
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
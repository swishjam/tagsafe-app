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
        page_url: page_url_to_audit, 
        tag_url: @tag.url_based_on_preferences,
        request_url_to_overwrite: @tag.full_url,
        request_url_to_overwrite_to: should_use_tagsafe_hosted_tag_version? ? @audit.tag_version.js_file_url : @tag.full_url,
        main_thread_blocking_multiplier: 0.2,
        total_main_thread_execution_multiplier: 0.1,
        main_thread_execution_audit_component_uid: @main_thread_execution_audit_component.uid
      }
    end

    def should_use_tagsafe_hosted_tag_version?
      @tag.is_tagsafe_hosted? && @audit.tag_version.present?
    end

    def page_url_to_audit
      "#{@page_url.url_without_query_params}#{@disable_tagsafe_js_on_page_url ? '?tagsafe-disabled=true' : ''}"
    end
  end
end
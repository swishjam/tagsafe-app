module StepFunctionResponses
  class JsCoverageResult < Base
    def process_results!
      if step_function_successful?
        js_usage_audit_component.completed!(
          score: response_payload['score'],
          raw_results: response_payload['raw_results']
        )
      else
        js_usage_audit_component.failed!(step_function_error_message)
      end
    end

    def js_usage_audit_component
      @js_usage_audit_component ||= JsUsageAuditComponent.find_by!(uid: request_payload['js_usage_audit_component_uid'])
    end
    alias record js_usage_audit_component
  end
end
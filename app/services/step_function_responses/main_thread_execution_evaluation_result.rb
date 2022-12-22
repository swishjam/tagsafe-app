module StepFunctionResponses
  class MainThreadExecutionEvaluationResult < Base
    def process_results!
      if step_function_successful?
        main_thread_execution_audit_component.completed!(
          score: response_payload['score'],
          raw_results: response_payload['raw_results']
        )
      else
        main_thread_execution_audit_component.failed!(step_function_error_message)
      end
    end

    def main_thread_execution_audit_component
      @main_thread_execution_audit_component ||= MainThreadExecutionAuditComponent.find_by!(uid: request_payload['main_thread_execution_audit_component_uid'])
    end
    alias record main_thread_execution_audit_component
  end
end
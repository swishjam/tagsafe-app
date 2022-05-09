module StepFunctionResponses
  class EventRouter
    attr_accessor :lambda_event_payload

    def initialize(lambda_event_payload)
      # TODO: when is the event payload `requestPayload` and `responsePayload` nested in `detail` vs root?
      @lambda_event_payload = lambda_event_payload.dig('detail') || lambda_event_payload
    end

    def route_event_to_respective_step_function_response_and_process!
      if event_results_processor_klass.has_executed_step_function?
        Rails.logger.info "Processing Step Function results with #{event_results_processor_klass.to_s} for #{event_results_processor&.record&.uid}..."
        event_results_processor.record.received_lambda_response!(
          response_payload: lambda_event_payload['responsePayload'] || {},
          response_code: step_function_failed? ? 500 : 202,
          error_message: step_function_failure_message
        )
      end
      event_results_processor.process_results!
    end

    private

    def event_results_processor
      @event_results_processor ||= event_results_processor_klass.new(lambda_event_payload)
    end

    def event_results_processor_klass
      @event_results_processor_klass ||= (
        lambda_event_payload.dig('requestPayload', 'tagsafe_consumer_klass') || 
        lambda_event_payload['tagsafe_consumer_klass']
      ).constantize
    rescue => e
      raise LambdaEventResponseError::NoConsumerKlass, "Cannot process event result, invalid `tagsafe_consumer_klass` in Lambda invocation request payload: #{lambda_event_payload.dig('requestPayload', 'tagsafe_consumer_klass') || lambda_event_payload['tagsafe_consumer_klass']}"
    end

    def step_function_failed?
      lambda_event_payload['step_function_error'].present?
    end

    def step_function_failure_message
      JSON.parse(lambda_event_payload.dig('step_function_error', 'Cause'))['errorMessage']
    rescue => e
      lambda_event_payload.dig('step_function_error', 'Cause')
    end
  end
end
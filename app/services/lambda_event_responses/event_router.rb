module LambdaEventResponses
  class EventRouter
    attr_accessor :lambda_event_payload

    def initialize(lambda_event_payload)
      # TODO: when is the event payload `requestPayload` and `responsePayload` nested in `detail` vs root?
      @lambda_event_payload = lambda_event_payload.dig('detail') || lambda_event_payload
    end

    def route_event_to_respective_lambda_event_response_and_process!
      if event_results_processor_klass.has_executed_lambda_function? && event_results_processor.record.received_lambda_response?
        Rails.logger.warn "LambdaEventResponses::EventRouter - Received response for #{event_results_processor.record.uid} that was already received, skipping processing...."
      else
        process_result!
      end
    end

    private

    def process_result!
      start_time = Time.now
      Rails.logger.info "Beginning ProcessReceivedLambdaEventJob #{event_results_processor_klass}.process_results! ......"
      event_results_processor.record.received_lambda_response!(response_payload: lambda_event_payload['responsePayload']) if event_results_processor_klass.has_executed_lambda_function?
      event_results_processor.process_results!
      Rails.logger.info "Completed ProcessReceivedLambdaEventJob #{event_results_processor_klass}.process_results! in #{Time.now - start_time} seconds"
    end

    def event_results_processor
      @event_results_processor ||= event_results_processor_klass.new(lambda_event_payload)
    end

    def event_results_processor_klass
      @event_results_processor_klass||= (lambda_event_payload.dig('requestPayload', 'tagsafe_consumer_klass') || lambda_event_payload['tagsafe_consumer_klass']).constantize
    rescue => e
      raise LambdaEventResponseError::NoConsumerKlass, "Cannot process event result, invalid `tagsafe_consumer_klass` in Lambda invocation request payload: #{lambda_event_payload.dig('requestPayload', 'tagsafe_consumer_klass') || lambda_event_payload['tagsafe_consumer_klass']}"
    end
  end
end
module StepFunctionResponses
  class Base
    attr_reader :event_payload

    def initialize(event_payload)
      @event_payload = event_payload
    end

    def response_payload
      @response_payload ||= event_payload['responsePayload'] || {}
    end

    def request_payload
      @request_payload ||= step_function_failed? ? event_payload : event_payload['requestPayload']
    end

    def step_function_failed?
      step_function_error_message.present?
    end

    def step_function_successful?
      step_function_error_message.nil?
    end

    def step_function_error_message
      JSON.parse(event_payload.dig('step_function_error', 'Cause'))['errorMessage']
    rescue => e
      event_payload.dig('step_function_error', 'Cause')
    end

    def self.has_executed_step_function?
      true
    end

    def process_results!
      raise NoMethodError, "`process_results!` not defined, subclass #{self.class.to_s} must implement"
    end

    def record
      raise NoMethodError, "`record` not defined, subclass #{self.class.to_s} must implement"
    end
  end
end
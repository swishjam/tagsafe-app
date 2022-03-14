module LambdaEventResponses
  class Base
    attr_reader :event_payload

    def initialize(event_payload)
      @event_payload = event_payload
    end

    def response_payload
      @response_payload ||= event_payload['responsePayload']
    end

    def request_payload
      @request_payload ||= event_payload['requestPayload']
    end

    def process_results!
      raise "`process_results!` not defined, subclass #{self.class.to_s} must implement"
    end
  end
end
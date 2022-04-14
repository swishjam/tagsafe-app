module LambdaFunctionInvoker
  class Base
    LAMBDA_ENV = ENV['LAMBDA_ENVIRONMENT'] || Rails.env

    class << self
      attr_accessor :lambda_function, :lambda_service, :results_consumer_klass, :results_consumer_job_queue, :has_no_executed_lambda_function
    end

    def send!
      invoke_function!(async: true)
    end
    alias send_async! send!

    def send_synchronously!
      invoke_function!(async: false)
    end

    private

    def invoke_function!(async:)
      create_executed_lambda_function!
      response = TagsafeAws::Lambda.invoke_function(
        function_name: lambda_invoke_function_name,
        async: async,
        payload: request_payload_with_defaults.merge!(executed_lambda_function_uid: executed_lambda_function&.uid || 'none')
      )
      update_executed_lambda_function_with_response(response)
      response
    end

    def receiver_job_queue
      @receiver_job_queue || self.class.results_consumer_job_queue || TagsafeQueue.LAMBDA_RESULTS
    end

    def lambda_invoke_function_name
      raise LambdaFunctionError::InvalidInvocation, "Subclass #{self.class.to_s} must implement a `lambda_service` and `lambda_function` class attr_accessor" if self.class.lambda_service.nil? || self.class.lambda_function.nil?
      [self.class.lambda_service, LAMBDA_ENV, self.class.lambda_function].join('-')
    end

    def request_payload_with_defaults
      raise LambdaFunctionError::PayloadNotProvided, "Subclass #{self.class.to_s} must implement a `request_payload` method." unless defined?(request_payload)
      raise LambdaFunctionError::InvalidInvocation, "Subclass #{self.class.to_s} must implement a `results_consumer_klass` class attr_accessor" if self.class.results_consumer_klass.nil?
      request_payload.merge!(
        lambda_invoker_klass: self.class.to_s,
        tagsafe_consumer_klass: self.class.results_consumer_klass.to_s,
        tagsafe_consumer_redis_url: ENV['REDIS_URL'],
        ProcessReceivedLambdaEventJobQueue: receiver_job_queue
      )
    end

    def executed_lambda_function_parent
      raise LambdaFunctionError::InvalidInvocation, "Subclass must specify a `executed_lambda_function_parent` class method"
    end

    def executed_lambda_function
      return if self.class.has_no_executed_lambda_function
      @executed_lambda_function ||= ExecutedLambdaFunction.create!(
        parent: executed_lambda_function_parent,
        function_name: lambda_invoke_function_name,
        request_payload: request_payload_with_defaults,
        executed_at: Time.now
      )
    end
    alias create_executed_lambda_function! executed_lambda_function

    def update_executed_lambda_function_with_response(response)
      return if self.class.has_no_executed_lambda_function
      response_payload = response.payload.string.blank? ? {} : JSON.parse(response.payload.string)
      executed_lambda_function.update!(response_payload: response_payload, response_code: response.status_code)
    end
  end
end
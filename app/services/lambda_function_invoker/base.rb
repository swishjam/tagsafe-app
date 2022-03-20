module LambdaFunctionInvoker
  class Base
    attr_accessor :executed_lambda_function_parent
    LAMBDA_ENV = ENV['LAMBDA_ENVIRONMENT'] || Rails.env
    
    class << self
      attr_accessor :lambda_service_name, :lambda_function_name, :resque_queue_to_capture_results
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
        payload: request_payload.merge!({
          lambda_invoker_klass: self.class.to_s,
          executed_lambda_function_uid: executed_lambda_function.uid,
          ProcessReceivedLambdaEventJobQueue: receiver_job_queue
        })
      )
      update_executed_lambda_function_with_response(response)
      response
    end

    # TODO: do we need this...?
    # def lambda_error!(error_msg)
    #   on_lambda_failure(error_msg) if defined?(on_lambda_failure)
    #   false
    # end

    def self.lambda_service(name)
      self.lambda_service_name = name
    end

    def self.lambda_function(name)
      self.lambda_function_name = name
    end

    def self.receiver_job_queue(queue)
      self.resque_queue_to_capture_results = queue
    end

    def receiver_job_queue
      @receiver_job_queue || self.class.resque_queue_to_capture_results || :default
    end

    def lambda_invoke_function_name
      raise LambdaFunctionError::InvalidInvocation, "Subclass must specify a `lambda_service` and `lambda_function` class method" if self.class.lambda_service_name.nil? || self.class.lambda_function_name.nil?
      [self.class.lambda_service_name, LAMBDA_ENV, self.class.lambda_function_name].join('-')
    end

    def request_payload
      raise LambdaFunctionError::PayloadNotProvided, 'Subclass must implement a `request_payload` method.'
    end

    def executed_lambda_function
      @executed_lambda_function ||= ExecutedLambdaFunction.create!(
        parent: executed_lambda_function_parent,
        function_name: lambda_invoke_function_name,
        request_payload: request_payload,
        executed_at: Time.now
      )
    end
    alias create_executed_lambda_function! executed_lambda_function

    def update_executed_lambda_function_with_response(response)
      response_payload = response.payload.string.blank? ? {} : JSON.parse(response.payload.string)
      executed_lambda_function.update!(response_payload: response_payload, response_code: response.status_code)
    end
  end
end
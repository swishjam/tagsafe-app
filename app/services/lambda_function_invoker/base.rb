module LambdaFunctionInvoker
  class Base
    LAMBDA_ENV = ENV['LAMBDA_ENVIRONMENT'] || Rails.env

    class << self
      attr_accessor :_lambda_function, :_lambda_service, :_consumer_klass, :_receiver_job_queue, :_has_no_executed_lambda_function
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
      @receiver_job_queue || provided_receiver_job_queue || :normal
    end

    def lambda_invoke_function_name
      raise LambdaFunctionError::InvalidInvocation, "Subclass must specify a `lambda_service` and `lambda_function` class method" if provided_lambda_service.nil? || provided_lambda_function.nil?
      [provided_lambda_service, LAMBDA_ENV, provided_lambda_function].join('-')
    end

    def request_payload_with_defaults
      raise LambdaFunctionError::PayloadNotProvided, 'Subclass must implement a `request_payload` method.' unless defined?(request_payload)
      request_payload.merge!(
        lambda_invoker_klass: self.class.to_s,
        tagsafe_consumer_klass: provided_consumer_klass.to_s,
        tagsafe_consumer_redis_url: ENV['REDIS_URL'],
        ProcessReceivedLambdaEventJobQueue: receiver_job_queue
      )
    end

    def executed_lambda_function_parent
      raise LambdaFunctionError::InvalidInvocation, "Subclass must specify a `executed_lambda_function_parent` class method"
    end

    def executed_lambda_function
      return if has_no_executed_lambda_function?
      @executed_lambda_function ||= ExecutedLambdaFunction.create!(
        parent: executed_lambda_function_parent,
        function_name: lambda_invoke_function_name,
        request_payload: request_payload_with_defaults,
        executed_at: Time.now
      )
    end
    alias create_executed_lambda_function! executed_lambda_function

    def update_executed_lambda_function_with_response(response)
      return if has_no_executed_lambda_function?
      response_payload = response.payload.string.blank? ? {} : JSON.parse(response.payload.string)
      executed_lambda_function.update!(response_payload: response_payload, response_code: response.status_code)
    end

    # attr_accessors API
    def self.lambda_service(val)
      self._lambda_service = val
    end

    def self.lambda_function(val)
      self._lambda_function = val
    end

    def self.consumer_klass(val)
      self._consumer_klass = val
    end

    def self.receiver_job_queue(val)
      self._receiver_job_queue = val
    end

    def self.has_no_executed_lambda_function
      self._has_no_executed_lambda_function = true
    end

    def provided_lambda_service
      self.class._lambda_service
    end

    def provided_lambda_function
      self.class._lambda_function
    end

    def provided_consumer_klass
      self.class._consumer_klass
    end

    def provided_receiver_job_queue
      self.class._receiver_job_queue
    end

    def has_no_executed_lambda_function?
      self.class._has_no_executed_lambda_function == true
    end
  end
end
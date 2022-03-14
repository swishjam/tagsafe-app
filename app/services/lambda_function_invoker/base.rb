module LambdaFunctionInvoker
  class Base
    attr_accessor :executed_lambda_function_parent
    LAMBDA_ENV = ENV['LAMBDA_ENVIRONMENT'] || Rails.env
    
    class << self
      attr_accessor :lambda_service_name, :lambda_function_name
    end

    def send!(async: true)
      create_executed_lambda_function!
      response = lambda_client.invoke(invoke_params(async: async))
      executed_lambda_function.update!(response_code: response.status_code)
      response.function_error ? lambda_error!(response.function_error) : response
    rescue => e
      executed_lambda_function.update!(
        response_code: 500,
        response_payload: { 
          errorMessage: e.message,
          errorBacktrac: e.backtrace 
        }
      )
      lambda_error!(e.message)
    end
    alias send_async! send!

    def send_synchronously!
      response = send!(async: false)
      if response
        response = JSON.parse(response.payload.string) 
        executed_lambda_function.update!(response_payload: response)
        response
      end
    end

    private

    def lambda_error!(error_msg)
      on_lambda_failure(error_msg) if defined?(on_lambda_failure)
      false
    end

    def lambda_client
      @lambda_client ||= Aws::Lambda::Client.new(
        access_key_id: ENV['AWS_ACCESS_KEY_ID'],
        secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
        region: 'us-east-1',
        max_attempts: 1,
        retry_limit: 0,
        http_read_timeout: @http_read_timeout || 210 # 3.5 mins
      )
    end

    def invoke_params(async: true)
      ensure_arguments!
      {
        function_name: lambda_invoke_function_name,
        invocation_type: async ? 'Event' : 'RequestResponse',
        log_type: 'Tail',
        payload: JSON.generate(
          request_payload.merge!({
            lambda_invoker_klass: self.class.to_s,
            executed_lambda_function_id: executed_lambda_function.id,
            executed_lambda_function_uid: executed_lambda_function.uid,
            ProcessReceivedLambdaEventJobQueue: 'default'
          })
        )
      }
    end

    def self.lambda_service(name)
      self.lambda_service_name = name
    end

    def self.lambda_function(name)
      self.lambda_function_name = name
    end

    def lambda_invoke_function_name
      raise LambdaFunctionError::InvalidInvocation, "Subclass must specify a `lambda_service` and `lambda_function` class method" if self.class.lambda_service_name.nil? || self.class.lambda_function_name.nil?
      [self.class.lambda_service_name, LAMBDA_ENV, self.class.lambda_function_name].join('-')
    end

    def ensure_arguments!
      missing_args = required_payload_arguments.select{ |req_arg| request_payload[req_arg].nil? }
      raise LambdaFunctionError::InvalidFunctionArguments, "#{lambda_invoke_function_name} is missing #{missing_args.join(', ')} arguments" if missing_args.any?
    end

    def required_payload_arguments
      []
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
  end
end
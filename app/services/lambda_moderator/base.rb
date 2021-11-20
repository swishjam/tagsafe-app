module LambdaModerator
  class Base
    attr_accessor :executed_lambda_function, :executed_lambda_function_parent
    LAMBDA_ENV = ENV['LAMBDA_ENVIRONMENT'] || Rails.env
    
    class << self
      attr_accessor :lambda_service_name, :lambda_function_name
    end

    def send!
      create_executed_lambda_function!
      response = lambda_client.invoke(invoke_params)
      response_body = JSON.parse(response.payload.read)
      update_executed_lambda_function_with_response(response.status_code, response_body)
      successful = response.status_code.between?(199, 299)
      OpenStruct.new(successful: successful, response_body: response_body, error: response.function_error || response_body['errorMessage'] || response_body['error'])
    rescue => e
      OpenStruct.new(successful: false, error: e.message, response_body: {})
    end

    private

    def lambda_client
      @lambda_client ||= Aws::Lambda::Client.new(
        access_key_id: ENV['AWS_ACCESS_KEY_ID'],
        secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
        region: 'us-east-1',
        max_attempts: 1,
        retry_limit: 0,
        http_read_timeout: @http_read_timeout || 210 # 3.5 mins for performance audits?
      )
    end

    def invoke_params
      ensure_arguments!
      {
        function_name: lambda_invoke_function_name,
        invocation_type: 'RequestResponse',
        log_type: 'Tail',
        payload: JSON.generate(request_payload)
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

    def create_executed_lambda_function!
      @executed_lambda_function ||= ExecutedLambdaFunction.create!(
        parent: executed_lambda_function_parent,
        function_name: lambda_invoke_function_name,
        request_payload: request_payload
      )
    end

    def update_executed_lambda_function_with_response(status_code, response_body)
      executed_lambda_function.update!(
        response_code: status_code, 
        response_payload: response_body,
        aws_log_stream_name: response_body && response_body['aws_log_stream_name'],
        aws_request_id: response_body && response_body['aws_request_id'],
        aws_trace_id: response_body && response_body['aws_trace_id']
      )
    # rescue Mysql2::Error => e
    #   executed_lambda_function.update!(response_code: status_code, response_payload: 'TOO LONG')
    end
  end
end
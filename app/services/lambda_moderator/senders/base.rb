module LambdaModerator
  module Senders
    class Base
      class PayloadNotProvided < StandardError; end;
      class InvalidLambdaFunction < StandardError; end;
      class InvalidLambdaFunctionArguments < StandardError; end;
      class FailedLambdaInvocation < StandardError; end;

      attr_accessor :endpoint, :request_body, :domain
      
      class << self
        attr_accessor :lambda_service_name, :lambda_function_name
      end

      def send!(async = true)
        start_time = Time.now
        Rails.logger.info "Invoking #{lambda_invoke_function_name} Lambda function with #{invoke_params}"
        Resque.logger.info "Invoking #{lambda_invoke_function_name} Lambda function with #{invoke_params}"
        
        response = lambda_client.invoke(invoke_params)
        
        Rails.logger.info "Completed #{lambda_invoke_function_name} Lambda function in #{Time.now - start_time} seconds."
        Resque.logger.info "Completed #{lambda_invoke_function_name} Lambda function in #{Time.now - start_time} seconds."

        return response if response.status_code.between?(199, 300)
        handle_lambda_error(response.function_error)
      rescue => e
        Rails.logger.info "#{lambda_invoke_function_name} Lambda function threw an error after #{Time.now - start_time} seconds."
        Resque.logger.info "#{lambda_invoke_function_name} Lambda function threw an error after #{Time.now - start_time} seconds."
        handle_lambda_error(e.message)
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
          invocation_type: @run_syncronously ? 'RequestResponse' : 'Event',
          log_type: 'Tail',
          payload: JSON.generate(request_payload)
        }
      end

      def handle_lambda_error(err_msg)
        Rails.logger.error "Error encountered in #{lambda_invoke_function_name} Lambda invocation: #{err_msg}"
        payload_struct = OpenStruct.new(read: JSON.generate({ 'functionName' => lambda_invoke_function_name, 'requestPayload' => request_payload, 'errorMessage' => err_msg }))
        OpenStruct.new(status_code: 500, payload: payload_struct)
      end

      def self.lambda_service(name)
        self.lambda_service_name = name
      end

      def self.lambda_function(name)
        self.lambda_function_name = name
      end

      def lambda_invoke_function_name
        raise InvalidLambdaFunction, "Subclass must specify a `lambda_service` and `lambda_function` class method" if self.class.lambda_service_name.nil? || self.class.lambda_function_name.nil?
        [self.class.lambda_service_name, lambda_environment, self.class.lambda_function_name].join('-')
      end

      def lambda_environment
        ENV['LAMBDA_ENVIRONMENT'] || Rails.env
      end

      def ensure_arguments!
        missing_args = required_payload_arguments.select{ |req_arg| request_payload[req_arg].nil? }
        raise InvalidLambdaFunctionArguments, "#{lambda_invoke_function_name} is missing #{missing_args.join(', ')} arguments" if missing_args.any?
      end

      def required_payload_arguments
        []
      end

      def request_payload
        raise PayloadNotProvided, 'Subclass must implement a `request_payload` method.'
      end
    end
  end
end
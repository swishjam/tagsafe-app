module GeppettoModerator
  module LambdaSenders
    class Base
      class PayloadNotProvided < StandardError; end;
      class InvalidLambdaFunction < StandardError; end;
      class InvalidLambdaFunctionArguments < StandardError; end;
      class FailedLambdaInvocation < StandardError; end;

      attr_accessor :endpoint, :request_body, :domain
      
      class << self
        attr_accessor :lambda_service_name, :lambda_function_name
      end

      def send!
        Rails.logger.info "Invoking #{lambda_invoke_function_name} function with #{invoke_params}"
        response = lambda_client.invoke(invoke_params)
        # if response.status_code != 202
        #   raise FailedLambdaInvocation, "#{lambda_invoke_function_name} invocation failed: \nstatus_code: #{response.status_code} \nfunction_error: #{response.function_error} \npayload: #{response.payload.read}"
        # end
      end

      private

      def lambda_client
        @lambda_client ||= Aws::Lambda::Client.new(region: 'us-east-1')
      end

      def invoke_params
        ensure_arguments!
        {
          function_name: lambda_invoke_function_name,
          invocation_type: 'Event',
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
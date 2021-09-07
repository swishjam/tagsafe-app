module GeppettoModerator
  module LambdaSenders
    class Base
      class PayloadNotProvided < StandardError; end;
      class InvalidLambdaFunction < StandardError; end;
      class InvalidLambdaFunctionArguments < StandardError; end;

      attr_accessor :endpoint, :request_body, :domain
      class << self
        attr_accessor :lambda_service_name, :lambda_function_name
      end

      def send!
        # GeppettoModerator::Sender.new(endpoint, domain, request_body).send!
        lambda_client.invoke(invoke_params)
      end

      private

      def lambda_client
        @lambda_client ||= Aws::Lambda::Client.new(region: 'us-east-1')
      end

      def invoke_params
        raise InvalidLambdaFunctionArguments, "#{lambda_function_name} requires the following payload arguments: #{required_payload_arguments}" unless has_valid_arguments?
        {
          function_name: lambda_function_name,
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

      def lambda_function_name
        raise InvalidLambdaFunction, "Subclass must specify a `lambda_service` and `lambda_function` class method" if self.class.lambda_service_name.nil? || self.class.lambda_function_name.nil?
        [self.class.lambda_service_name, lambda_environment, self.class.lambda_function_name].join('-')
      end

      def lambda_environment
        ENV['LAMBDA_ENVIRONMENT'] || Rails.env
      end

      def has_valid_arguments?
        required_payload_arguments.any?{ |arg| request_payload[arg].nil? }
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
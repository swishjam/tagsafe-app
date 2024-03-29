module StepFunctionInvoker
  class Base
    LAMBDA_ENV = ENV['LAMBDA_ENVIRONMENT'] || Rails.env
    LAMBDA_REGION = ENV['LAMBDA_REGION'] || 'us-east-1'
    ENV_AWS_ARN_ID_DICTIONARY = {
      'collin-dev' => '328640749123',
      'staging' => '538833274413',
      'production' => '407342930315'
    }

    class << self
      attr_accessor :step_function_name, :results_consumer_klass, :results_consumer_job_queue, :has_no_executed_step_function
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
      create_executed_step_function!
      response = TagsafeAws::StateMachine.execute(
        arn: step_function_arn,
        name: unique_execution_name,
        input: request_payload_with_defaults.merge!(executed_step_function_uid: executed_step_function&.uid || 'none')
      )
      update_executed_step_function_with_execution_arn(response)
      response
    end

    def step_function_arn
      # "arn:aws:states:us-east-1:407342930315:stateMachine:production-run-performance-audit"
      "arn:aws:states:#{self.class::LAMBDA_REGION}:#{self.class::ENV_AWS_ARN_ID_DICTIONARY[self.class::LAMBDA_ENV]}:stateMachine:#{self.class::LAMBDA_ENV}-#{self.class.step_function_name}"
    end

    def receiver_job_queue
      @receiver_job_queue || self.class.results_consumer_job_queue || TagsafeQueue.LAMBDA_RESULTS
    end

    def unique_execution_name
      "#{self.class.to_s.split('::').last}-#{unique_identifer}"
    end

    def unique_identifer
      executed_step_function_parent&.uid || begin
        raise LambdaFunctionError::InvalidInvocation, "#{self.class.to_s} must define a `unique_identifer` if there it has no `executed_step_function_parent`"
      end
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

    def executed_step_function_parent
      raise LambdaFunctionError::InvalidInvocation, "Subclass must specify a `executed_step_function_parent` class method"
    end

    def executed_step_function
      return if self.class.has_no_executed_step_function
      @executed_step_function ||= ExecutedStepFunction.create!(
        parent: executed_step_function_parent,
        step_function_execution_name: unique_execution_name,
        request_payload: request_payload_with_defaults,
        executed_at: Time.now
      )
    end
    alias create_executed_step_function! executed_step_function

    def update_executed_step_function_with_execution_arn(response)
      return if self.class.has_no_executed_step_function
      raise StandardError, "Executed Step Function for #{executed_step_function_parent&.uid || '[no parent]'} does not have an execution arn. AWS Step Function Response: #{response.inspect}" if response.execution_arn.nil?
      executed_step_function.update!(step_function_execution_arn: response.execution_arn)
    end
  end
end
require 'rails_helper'

RSpec.describe LambdaFunctionInvoker::Base do
  module LambdaFunctionInvoker
    module Senders
      class MockSender < Base
        lambda_service 'mock-service'
        lambda_function 'mockFunction'
        def request_payload; { foo: 'bar' }; end
      end
    end
  end

  before(:each) do
    stub_lambda_calls
    @mock_sender = LambdaFunctionInvoker::MockSender.new
  end

  describe 'class attr_accessors' do
    it 'defines lambda_service_name and lambda_function_name' do
      expect(LambdaFunctionInvoker::MockSender.lambda_service_name).to eq('mock-service')
      expect(LambdaFunctionInvoker::MockSender.lambda_function_name).to eq('mockFunction')
    end
  end

  describe '#send!' do
    it 'invokes a lambda function' do
      expect_any_instance_of(Aws::Lambda::Client).to receive(:invoke).exactly(:once)
      @mock_sender.send!
    end
  end

  describe '#lambda_client' do
    it 'initialize an AWS Lambda client and memoizes it' do
      expect(Aws::Lambda::Client).to receive(:new).with({ region: 'us-east-1' }).exactly(:once).and_call_original
      @mock_sender.send(:lambda_client)
      @mock_sender.send(:lambda_client)
    end
  end

  describe '#invoke_params' do
    it 'calls ensure_arguments!' do
      expect(@mock_sender).to receive(:ensure_arguments!).exactly(:once)
      @mock_sender.send(:invoke_params)
    end

    it 'returns the formatted invoke arguments' do
      expect(@mock_sender.send(:invoke_params)).to eq({
        function_name: 'mock-service-test-mockFunction',
        invocation_type: 'Event',
        log_type: 'Tail',
        payload: JSON.generate({ foo: 'bar' })
      })
    end
  end

  describe '#self.lambda_service' do
    it 'sets the lambda_service_name class variables' do
      LambdaFunctionInvoker::Base.lambda_service 'test!'
      expect(LambdaFunctionInvoker::Base.lambda_service_name).to eq('test!')
    end
  end

  describe '#self.lambda_function' do
    it 'sets the lambda_function_name class variables' do
      LambdaFunctionInvoker::Base.lambda_function 'test!'
      expect(LambdaFunctionInvoker::Base.lambda_function_name).to eq('test!')
    end
  end

  describe '#lambda_invoke_function_name' do
    it 'throws an error if lambda_function_name is not defined' do
      @mock_sender.class.lambda_function nil
      expect{ @mock_sender.send(:lambda_invoke_function_name) }.to raise_error(LambdaFunctionInvoker::Base::InvalidLambdaFunction)
      @mock_sender.class.lambda_function 'mockFunction'
    end

    it 'throws an error if lambda_service_name is not defined' do
      @mock_sender.class.lambda_service nil
      expect{ @mock_sender.send(:lambda_invoke_function_name) }.to raise_error(LambdaFunctionInvoker::Base::InvalidLambdaFunction)
      @mock_sender.class.lambda_service 'mock-service'
    end

    it 'returns the formatted Lambda function name' do
      expect(@mock_sender.send(:lambda_invoke_function_name)).to eq('mock-service-test-mockFunction')
    end
  end

  describe '#lambda_environment' do
    it 'uses the LAMBDA_ENVIRONMENT ENV if defined' do
      ENV['LAMBDA_ENVIRONMENT'] = 'spec-test'
      expect(@mock_sender.send(:lambda_environment)).to eq('spec-test')
      ENV.delete('LAMBDA_ENVIRONMENT')
    end

    it 'uses the Rails.env if LAMBDA_ENVIRONMENT is undefined' do
      expect(@mock_sender.send(:lambda_environment)).to eq('test')
    end
  end

  describe '#ensure_arguments!' do
    it 'does not raise an error if the required payload is present' do
      expect(@mock_sender.send(:ensure_arguments!)).to eq(nil)
    end

    it 'raises an error if a required payload argument is missing' do
      allow(@mock_sender).to receive(:required_payload_arguments).and_return([:foo ,:missing_arg])
      expect{ @mock_sender.send(:ensure_arguments!) }.to raise_error(LambdaFunctionInvoker::Base::InvalidLambdaFunctionArguments, "mock-service-test-mockFunction is missing missing_arg arguments")
    end
  end
end
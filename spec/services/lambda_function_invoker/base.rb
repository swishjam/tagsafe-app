require 'rails_helper'

RSpec.describe StepFunctionInvoker::Base do
  module StepFunctionInvoker
    class DummyLambdaInvoker < Base
      lambda_service = 'some-service!' 
      lambda_function = 'some-function!'
      receiver_job_queue = TagsafeQueue.LOW
      consumer_klass = Struct
    end
  end

  module StepFunctionInvoker; class NoRequestPayloadClass < DummyLambdaInvoker; end; end;

  before(:each) do
    prepare_test!(bypass_default_domain_create: true)
  end

  describe '#request_payload_with_defaults' do
    it 'throws an error if the sub-class has not defined `request_payload`' do
      dummy_instance = StepFunctionInvoker::NoRequestPayloadClass.new
      expect{ 
        dummy_instance.send(:request_payload_with_defaults) 
      }.to raise_error(LambdaFunctionError::PayloadNotProvided)
    end
  end

  describe '#receiver_job_queue' do
    it 'uses the receiver_job_queue instance variable when specified' do
      dummy_instance = StepFunctionInvoker::DummyLambdaInvoker.new
      dummy_instance.instance_variable_set(:@receiver_job_queue, :instance_variable_defined_queue)
      expect(dummy_instance.send(:receiver_job_queue)).to eq(:instance_variable_defined_queue)
    end

    it 'uses the `receiver_job_queue` attr_accessor when specified' do
      dummy_instance = StepFunctionInvoker::DummyLambdaInvoker.new
      expect(dummy_instance.send(:receiver_job_queue)).to eq(:low)
    end
    
    it 'defaults to `:normal` when not specified' do
      # StepFunctionInvoker::DummyLambdaInvoker.receiver_job_queue = nil
      class StepFunctionInvoker::NoQueueDefined < StepFunctionInvoker::Base; end;
      dummy_instance = StepFunctionInvoker::NoQueueDefined.new
      expect(dummy_instance.send(:receiver_job_queue)).to eq(:normal)
    end
  end
end
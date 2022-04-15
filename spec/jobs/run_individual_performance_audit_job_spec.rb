require 'rails_helper'

RSpec.describe AuditRunnerJobs::RunIndividualPerformanceAudit do
  before(:each) do
    prepare_test!
    @tag = create(:tag, domain: @domain)
    @tag_version = create(:tag_version, tag: @tag)
    url_to_audit = create(:url_to_audit, tag: @tag)
    @audit = create(:pending_audit, tag: @tag, tag_version: @tag_version, audited_url: url_to_audit, execution_reason: ExecutionReason.MANUAL)
    allow(PerformanceAuditManager::ResultsCapturer).to receive(:new).and_return(OpenStruct.new(evaluate!: 'stub'))
  end

  def perform_job
    AuditRunnerJobs::RunIndividualPerformanceAudit.perform_now(
      audit: @audit,
      lambda_sender_class: StepFunctionInvoker::PerformanceAuditerWithTag
    )
  end

  describe '#perform_later' do
    it 'initializes the `lambda_sender_class`' do
      expect(StepFunctionInvoker::PerformanceAuditerWithTag).to receive(:new).with(
        audit: @audit, 
        tag_version: @tag_version, 
      ).exactly(:once).and_call_original
      perform_job
    end

    it 'calls `send!` on an instance of the `lambda_sender_class`' do
      success_response = OpenStruct.new(successful: true, response_body: { foo: 'bar' }, error: nil)
      expect_any_instance_of(StepFunctionInvoker::PerformanceAuditerWithTag).to receive(:send!).exactly(:once).and_return(success_response)
      perform_job
    end

    it 'calls `capture_successful_response` when the response of the sender `send!` call is successful' do
      successful_response = OpenStruct.new(successful: true, response_body: { foo: 'bar' }, error: nil)
      expect_any_instance_of(StepFunctionInvoker::PerformanceAuditerWithTag).to receive(:send!).exactly(:once).and_return(successful_response)
      expect_any_instance_of(AuditRunnerJobs::RunIndividualPerformanceAudit).to receive(:capture_successful_response).with({ foo: 'bar' }, @audit)
      perform_job
    end

    it 'calls `error!` on the lambda_sender_class individual_performance_audit when the response of the sender `send!` call is unsuccessful' do
      unsuccessful_response = OpenStruct.new(successful: false, response_body: { foo: 'bar' }, error: 'Oops! An error occurred.')
      expect_any_instance_of(StepFunctionInvoker::PerformanceAuditerWithTag).to receive(:send!).exactly(:once).and_return(unsuccessful_response)
      expect_any_instance_of(PerformanceAuditWithTag).to receive(:error!).with('Oops! An error occurred.').exactly(:once)
      perform_job
    end
  end
end
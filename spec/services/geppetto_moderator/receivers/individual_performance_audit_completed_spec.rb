require 'rails_helper'

RSpec.describe LambdaFunctionInvoker::Receivers::IndividualPerformanceAuditCompleted do
  before(:each) do
    prepare_test!
    tag = create(:tag, domain: @domain)
    tag_version = create(:tag_version, tag: tag)
    audit = create(:audit, tag: tag, tag_version: tag_version, execution_reason: ExecutionReason.MANUAL)
    individual_performance_audit = create(:individual_performance_audit_with_tag, audit: audit)

    @results = 'RESULTS STUB'
    @logs = 'LOGS STUB'
    @error = 'ERROR STUB'
    @individual_performance_audit_id = individual_performance_audit.id
    @completed_receiver = LambdaFunctionInvoker::Receivers::IndividualPerformanceAuditCompleted.new(
      individual_performance_audit_id: @individual_performance_audit_id,
      results: @results,
      logs: @logs,
      error: @error,
      num_attempts: @num_attempts
    )
  end

  describe '#receive!' do
    it 'enqueues the IndividualPerformanceAuditCompletedJob job' do
      expect(IndividualPerformanceAuditCompletedJob).to receive(:perform_later).with({
        individual_performance_audit_id: @individual_performance_audit_id,
        results: @results,
        logs: @logs,
        error: @error,
        num_attempts: @num_attempts
      })
      @completed_receiver.receive!
    end
  end
end
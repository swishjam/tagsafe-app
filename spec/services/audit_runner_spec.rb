require 'rails_helper'

RSpec.describe AuditRunner do
  before(:each) do
    prepare_test!
    @tag = create(:tag, domain: @domain)
    @tag_version =  create(:tag_version, tag: @tag)
    create(:tag_preference, performance_audit_iterations: 5, tag: @tag)
    @url_to_audit = create(:url_to_audit, tag: @tag, display_url: 'https://www.tagsafe.io', audit_url: 'https://www.tagsafe.io', tagsafe_hosted: false)
    
    @runner = AuditRunner.new(
      tag_version: @tag_version,
      execution_reason: ExecutionReason.MANUAL,
      audit: nil,
      url_to_audit_id: @url_to_audit.id, 
      enable_tracing: false,
      attempt_number: 0
    )
  end

  describe '#initialize' do
    it 'uses the provided Audit or creates a new one if none was given' do
      expect(@runner.send(:audit).id).to_not be(nil)
      
      audit = create(:audit, tag_version: @tag_version, tag: @tag, execution_reason: ExecutionReason.MANUAL, audited_url: @url_to_audit)
      runner_with_audit = AuditRunner.new(
        tag_version: @tag_version,
        execution_reason: ExecutionReason.MANUAL,
        audit: audit,
        url_to_audit_id: @url_to_audit.id, 
        enable_tracing: false,
        attempt_number: 0
      )
      expect(runner_with_audit.send(:audit)).to be(audit)
    end
  end

  describe '#run!' do
    it 'calls run_performance_audit!' do
      expect(@runner).to receive(:run_performance_audit!).exactly(:once)
      @runner.run!
    end
  end

  describe '#run_performance_audit!' do
    it 'runs a performance audit with the tag and without the tag as many times as the tag_preferences performance_audit_iterations states' do
      with_tag_audits_sent_count = 0
      without_tag_audits_sent_count = 0
      allow(AuditRunnerJobs::RunIndividualPerformanceAudit).to receive(:perform_later).with({
        audit: @runner.send(:audit),
        tag_version: @tag_version, 
        enable_tracing: false,
        lambda_sender_class: StepFunctionInvoker::PerformanceAuditerWithTag
      }) { with_tag_audits_sent_count += 1 }
      allow(AuditRunnerJobs::RunIndividualPerformanceAudit).to receive(:perform_later).with({
        audit: @runner.send(:audit),
        tag_version: @tag_version, 
        enable_tracing: false,
        lambda_sender_class: StepFunctionInvoker::PerformanceAuditerWithoutTag
      }) { without_tag_audits_sent_count += 1 }
      @runner.send(:run_performance_audit!)

      expect(with_tag_audits_sent_count).to be(5)
      expect(without_tag_audits_sent_count).to be(5)
    end
  end

  describe '#audit' do
    it 'creates a new Audit and memoizes it' do
      @runner.send(:audit)
      @runner.send(:audit)
      @runner.send(:audit)

      expect(@runner.send(:audit).tag_version).to eq(@tag_version)
      expect(@runner.send(:audit).tag).to eq(@tag)
      expect(@runner.send(:audit).execution_reason).to eq(ExecutionReason.MANUAL)
      expect(@runner.send(:audit).performance_audit_iterations).to eq(5)
    end
  end
end
require 'rails_helper'

RSpec.describe AuditRunner do
  before(:each) do
    prepare_test!
    @tag = create(:tag, domain: @domain)
    @tag_version =  create(:tag_version, tag: @tag)
    create(:tag_preference, performance_audit_iterations: 5, tag: @tag)
    
    @runner = AuditRunner.new(
      tag_version: @tag_version,
      execution_reason: ExecutionReason.MANUAL
    )
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
      allow_any_instance_of(GeppettoModerator::LambdaSenders::PerformanceAuditerWithTag).to receive(:send!) { with_tag_audits_sent_count += 1 }
      allow_any_instance_of(GeppettoModerator::LambdaSenders::PerformanceAuditerWithoutTag).to receive(:send!) { without_tag_audits_sent_count += 1 }
      @runner.send(:run_performance_audit!)

      expect(with_tag_audits_sent_count).to be(5)
      expect(without_tag_audits_sent_count).to be(5)
    end
  end

  describe '#performance_audit_runner_with_tag' do
    it 'initializes a GeppettoModerator::LambdaSenders::PerformanceAuditerWithTag and memoizes it' do
      expect(GeppettoModerator::LambdaSenders::PerformanceAuditerWithTag).to receive(:new).with({
        audit: @runner.send(:audit),
        tag_version: @tag_version
      }).exactly(:once).and_call_original
      
      @runner.send(:performance_audit_runner_with_tag)
      @runner.send(:performance_audit_runner_with_tag)
    end
  end

  describe '#performance_audit_runner_without_tag' do
    it 'initializes a GeppettoModerator::LambdaSenders::PerformanceAuditerWithTag and memoizes it' do
      expect(GeppettoModerator::LambdaSenders::PerformanceAuditerWithoutTag).to receive(:new).with({
        audit: @runner.send(:audit),
        tag_version: @tag_version
      }).exactly(:once).and_call_original
      
      @runner.send(:performance_audit_runner_without_tag)
      @runner.send(:performance_audit_runner_without_tag)
    end
  end

  describe '#audit' do
    it 'creates a new Audit and memoizes it' do
      expect(Audit).to receive(:new).exactly(:once).and_call_original
      @runner.send(:audit)
      @runner.send(:audit)

      expect(@runner.send(:audit).tag_version).to eq(@tag_version)
      expect(@runner.send(:audit).tag).to eq(@tag)
      expect(@runner.send(:audit).execution_reason).to eq(ExecutionReason.MANUAL)
      expect(@runner.send(:audit).performance_audit_url).to eq('https://www.example.com')
      expect(@runner.send(:audit).performance_audit_iterations).to eq(5)
    end
  end
end
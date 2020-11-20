require 'rails_helper'

RSpec.describe AuditRunner do
  before(:each) do
    stub_script_valid_url_validation
    domain = create(:domain)
    script = create(:script)
    @script_subscriber =  create(:script_subscriber, domain: domain, script: script)
    @script_change = create(:script_change, script: script)
    @execution_reason = create(:script_change_execution)
    create(:lighthouse_preference, script_subscriber: @script_subscriber)
    # have to reload in order for the lighthouse_preference to register? :\
    @script_subscriber.reload
    
    @runner = AuditRunner.new(script_subscriber: @script_subscriber, script_change: @script_change, execution_reason: @execution_reason)
  end

  describe '#run!' do
    it 'calls .send! on GeppettoModerator::Senders::RunLighthouseAudit' do
      expect_any_instance_of(GeppettoModerator::Senders::RunLighthouseAudit).to receive(:send!).exactly(:once).and_return(true)
      @runner.run!
    end
  end

  describe '#lighthouse_audit_runner' do
    it 'initializes a GeppettoModerator::Senders::RunLighthouseAudit with the correct arguments and is memoized' do
      expect(Audit).to receive(:create).exactly(:once).and_return('STUBBED_AUDIT')
      expect(GeppettoModerator::Senders::RunLighthouseAudit).to receive(:new).exactly(:once).with(
        audit: 'STUBBED_AUDIT',
        url_to_audit: @script_subscriber.lighthouse_preferences.url_to_audit,
        num_test_iterations: @script_subscriber.lighthouse_preferences.num_test_iterations,
        script_url: @script_subscriber.script.url
      ).and_return(true)
      lighthouse_audit1 = @runner.send(:lighthouse_audit_runner)
      lighthouse_audit2 = @runner.send(:lighthouse_audit_runner)
      expect(lighthouse_audit1).to be(lighthouse_audit2)
    end
  end

  describe '#audit' do
    it 'creates an audit with the correct arguments and is memoized' do
      expect(Audit).to receive(:create).exactly(:once).with(
        script_change: @script_change,
        script_subscriber: @script_subscriber,
        execution_reason: @execution_reason,
        lighthouse_audit_url: @script_subscriber.lighthouse_preferences.url_to_audit,
        lighthouse_audit_enqueued_at: DateTime.now,
        test_suite_enqueued_at: DateTime.now
      ).and_call_original
      audit1 = @runner.send(:audit)
      audit2 = @runner.send(:audit)
      expect(audit1).to be(audit2)
    end
  end
end
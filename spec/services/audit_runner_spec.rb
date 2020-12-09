require 'rails_helper'

RSpec.describe AuditRunner do
  before(:each) do
    stub_script_valid_url_validation
    stub_domain_scan
    @domain = create(:domain)
    @script = create(:script)
    @script_subscriber =  create(:script_subscriber, domain: @domain, script: @script)
    @script_change = create(:script_change, script: @script)
    @execution_reason = create(:script_change_execution)
    create(:performance_audit_preference, script_subscriber: @script_subscriber)
    # have to reload in order for the lighthouse_preference to register? :\
    @script_subscriber.reload
    
    @runner = AuditRunner.new(
      script_subscriber: @script_subscriber, 
      script_change: @script_change, 
      execution_reason: @execution_reason
    )
  end

  describe '#run!' do
    it 'calls .send! on GeppettoModerator::Senders::RunPerformanceAudit' do
      expect_any_instance_of(GeppettoModerator::Senders::RunPerformanceAudit).to receive(:send!).exactly(:once).and_return(true)
      @runner.run!
    end
  end

  describe '#performance_audit_runner' do
    it 'initializes a GeppettoModerator::Senders::RunPerformanceLighthouseAudit with the correct arguments and is memoized' do
      expect(Audit).to receive(:create).exactly(:once).and_return('STUBBED_AUDIT')
      expect(GeppettoModerator::Senders::RunPerformanceAudit).to receive(:new).exactly(:once).with(
        audit: 'STUBBED_AUDIT',
        audit_url: @script_subscriber.performance_audit_preferences.url_to_audit,
        num_test_iterations: @script_subscriber.performance_audit_preferences.num_test_iterations,
        third_party_tag_to_audit: @script_subscriber.script.url,
        third_party_tags_to_allow: []
      ).and_return(true)
      performance_audit1 = @runner.send(:performance_audit_runner)
      performance_audit2 = @runner.send(:performance_audit_runner)
      expect(performance_audit1).to be(performance_audit2)
    end

    it 'it creates a performance audit with the correct allowed third party tags when the domain has script subscriptions that are marked as is_third_party_tag: false' do
      script = create(:script, url: 'https://www.notathirdparty.com')
      create(:script_subscriber, domain: @domain, script: script, is_third_party_tag: false)
      
      expect(Audit).to receive(:create).exactly(:once).and_return('STUBBED_AUDIT')
      expect(GeppettoModerator::Senders::RunPerformanceAudit).to receive(:new).exactly(:once).with(
        audit: 'STUBBED_AUDIT',
        audit_url: @script_subscriber.performance_audit_preferences.url_to_audit,
        num_test_iterations: @script_subscriber.performance_audit_preferences.num_test_iterations,
        third_party_tag_to_audit: @script_subscriber.script.url,
        third_party_tags_to_allow: ['https://www.notathirdparty.com']
      ).and_return(true)
      @runner.send(:performance_audit_runner)
    end

    it 'it creates a performance audit with the correct allowed third party tags when the domain has script subscriptions that are marked as allowed_third_party_tage: true' do
      script = create(:script, url: 'https://www.tagmanagerthataddsalltheothertags.com')
      create(:script_subscriber, domain: @domain, script: script, is_third_party_tag: false)
      
      expect(Audit).to receive(:create).exactly(:once).and_return('STUBBED_AUDIT')
      expect(GeppettoModerator::Senders::RunPerformanceAudit).to receive(:new).exactly(:once).with(
        audit: 'STUBBED_AUDIT',
        audit_url: @script_subscriber.performance_audit_preferences.url_to_audit,
        num_test_iterations: @script_subscriber.performance_audit_preferences.num_test_iterations,
        third_party_tag_to_audit: @script_subscriber.script.url,
        third_party_tags_to_allow: ['https://www.tagmanagerthataddsalltheothertags.com']
      ).and_return(true)
      @runner.send(:performance_audit_runner)
    end
  end

  describe '#audit' do
    it 'creates an audit with the correct arguments and is memoized' do
      expect(Audit).to receive(:create).exactly(:once).with(
        script_change: @script_change,
        script_subscriber: @script_subscriber,
        execution_reason: @execution_reason,
        performance_audit_url: @script_subscriber.performance_audit_preferences.url_to_audit,
        performance_audit_enqueued_at: DateTime.now,
        test_suite_enqueued_at: DateTime.now,
        test_suite_completed_at: DateTime.now
      ).and_call_original
      audit1 = @runner.send(:audit)
      audit2 = @runner.send(:audit)
      expect(audit1).to be(audit2)
    end
  end
end
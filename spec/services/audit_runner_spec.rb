require 'rails_helper'

RSpec.describe AuditRunner do
  before(:each) do
    stub_script_valid_url_validation
    stub_domain_scan
    @domain = create(:domain)
    @script = create(:script)
    @tag =  create(:tag, domain: @domain, script: @script)
    @tag_version = create(:tag_version, script: @script)
    @execution_reason = create(:tag_version_execution)
    create(:performance_audit_preference, tag: @tag)
    # have to reload in order for the lighthouse_preference to register? :\
    @tag.reload
    
    @runner = AuditRunner.new(
      tag: @tag, 
      tag_version: @tag_version, 
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
        audit_url: @tag.performance_audit_preferences.url_to_audit,
        num_test_iterations: @tag.performance_audit_preferences.num_test_iterations,
        third_party_tag_to_audit: @tag.script.url,
        third_party_tags_to_allow: []
      ).and_return(true)
      performance_audit1 = @runner.send(:performance_audit_runner)
      performance_audit2 = @runner.send(:performance_audit_runner)
      expect(performance_audit1).to be(performance_audit2)
    end

    it 'it creates a performance audit with the correct allowed third party tags when the domain has script subscriptions that are marked as is_third_party_tag: false' do
      script = create(:script, url: 'https://www.notathirdparty.com')
      create(:tag, domain: @domain, script: script, is_third_party_tag: false)
      
      expect(Audit).to receive(:create).exactly(:once).and_return('STUBBED_AUDIT')
      expect(GeppettoModerator::Senders::RunPerformanceAudit).to receive(:new).exactly(:once).with(
        audit: 'STUBBED_AUDIT',
        audit_url: @tag.performance_audit_preferences.url_to_audit,
        num_test_iterations: @tag.performance_audit_preferences.num_test_iterations,
        third_party_tag_to_audit: @tag.script.url,
        third_party_tags_to_allow: ['https://www.notathirdparty.com']
      ).and_return(true)
      @runner.send(:performance_audit_runner)
    end

    it 'it creates a performance audit with the correct allowed third party tags when the domain has script subscriptions that are marked as allowed_third_party_tage: true' do
      script = create(:script, url: 'https://www.tagmanagerthataddsalltheothertags.com')
      create(:tag, domain: @domain, script: script, is_third_party_tag: false)
      
      expect(Audit).to receive(:create).exactly(:once).and_return('STUBBED_AUDIT')
      expect(GeppettoModerator::Senders::RunPerformanceAudit).to receive(:new).exactly(:once).with(
        audit: 'STUBBED_AUDIT',
        audit_url: @tag.performance_audit_preferences.url_to_audit,
        num_test_iterations: @tag.performance_audit_preferences.num_test_iterations,
        third_party_tag_to_audit: @tag.script.url,
        third_party_tags_to_allow: ['https://www.tagmanagerthataddsalltheothertags.com']
      ).and_return(true)
      @runner.send(:performance_audit_runner)
    end
  end

  describe '#audit' do
    it 'creates an audit with the correct arguments and is memoized' do
      expect(Audit).to receive(:create).exactly(:once).with(
        tag_version: @tag_version,
        tag: @tag,
        execution_reason: @execution_reason,
        performance_audit_url: @tag.performance_audit_preferences.url_to_audit,
        performance_audit_enqueued_at: DateTime.now
      ).and_call_original
      audit1 = @runner.send(:audit)
      audit2 = @runner.send(:audit)
      expect(audit1).to be(audit2)
    end
  end
end
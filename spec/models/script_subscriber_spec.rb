require 'rails_helper'

RSpec.describe ScriptSubscriber, type: :model do
  before(:each) do
    stub_script_valid_url_validation
    @domain = create(:domain)
    @domain_2 = create(:domain_2)
    @script = create(:script)
    @script_change = create(:script_change, script: @script)
    @script_subscriber = create(:script_subscriber, domain: @domain, script: @script)
    execution_reason = create(:manual_execution)

    @audit_with_pending_lighthouse1 = create(:audit_with_pending_lighthouse, 
      script_change: @script_change, 
      script_subscriber: @script_subscriber, 
      execution_reason: execution_reason,
      created_at: DateTime.now - 1.day
    )
    @audit_with_failed_lighthouse1 = create(:audit_with_failed_lighthouse, 
      script_change: @script_change, 
      script_subscriber: @script_subscriber, 
      execution_reason: execution_reason,
      created_at: DateTime.now - 2.days
    )
    @successful_audit1= create(:audit, 
      script_change: @script_change, 
      script_subscriber: @script_subscriber, 
      execution_reason: execution_reason,
      created_at: DateTime.now - 3.days
    )

    @audit_with_pending_lighthouse2 = create(:audit_with_pending_lighthouse, 
      script_change: @script_change, 
      script_subscriber: @script_subscriber, 
      execution_reason: execution_reason,
      created_at: DateTime.now - 2.days
    )
    @audit_with_failed_lighthouse2 = create(:audit_with_failed_lighthouse, 
      script_change: @script_change, 
      script_subscriber: @script_subscriber, 
      execution_reason: execution_reason,
      created_at: DateTime.now - 3.days
    )
    @successful_audit2 = create(:audit, 
      script_change: @script_change, 
      script_subscriber: @script_subscriber, 
      execution_reason: execution_reason,
      created_at: DateTime.now - 4.days
    )
  end

  describe '#most_recent_audit_by_script_change' do
    it 'returns the the most recent completed, successful lighthouse audit' do
      most_recent_audit = @script_subscriber.most_recent_audit_by_script_change(@script_change)
      expect(most_recent_audit).to eq(@successful_audit1)
    end

    it 'returns the the most recent successful OR unsuccesful lighthouse audit' do
      most_recent_audit = @script_subscriber.most_recent_audit_by_script_change(@script_change, include_failed_lighthouse_audits: true)
      expect(most_recent_audit).to eq(@audit_with_failed_lighthouse1)
    end

    it 'returns the the most recent pending OR incomplete lighthouse audit' do
      most_recent_audit = @script_subscriber.most_recent_audit_by_script_change(@script_change, include_pending_lighthouse_audits: true)
      expect(most_recent_audit).to eq(@audit_with_pending_lighthouse1)
    end

    it 'returns the the most recent pending OR failed audit' do
      most_recent_audit = @script_subscriber.most_recent_audit_by_script_change(@script_change, include_pending_lighthouse_audits: true, include_failed_lighthouse_audits: true)
      expect(most_recent_audit).to eq(@audit_with_pending_lighthouse1)
    end
  end

  describe '#audits_by_script_change' do
    it 'returns only completed, successful audits without arguments' do
      audits = @script_subscriber.audits_by_script_change(@script_change)
      expect(audits.include?(@audit_with_failed_lighthouse1)).to eq(false)
      expect(audits.include?(@audit_with_pending_lighthouse1)).to eq(false)
      expect(audits.include?(@successful_audit1)).to eq(true)
    end

    it 'returns the correct audits when include_pending_lighthouse_audits: false and include_failed_lighthouse_audits: false' do
      audits = @script_subscriber.audits_by_script_change(@script_change, include_pending_lighthouse_audits: false, include_failed_lighthouse_audits: false)
      expect(audits.include?(@audit_with_failed_lighthouse1)).to eq(false)
      expect(audits.include?(@audit_with_pending_lighthouse1)).to eq(false)
      expect(audits.include?(@successful_audit1)).to eq(true)
    end

    it 'returns the correct audits when include_pending_lighthouse_audits: false and include_failed_lighthouse_audits: true' do
      audits = @script_subscriber.audits_by_script_change(@script_change, include_pending_lighthouse_audits: false, include_failed_lighthouse_audits: true)
      expect(audits.include?(@audit_with_failed_lighthouse1)).to eq(true)
      expect(audits.include?(@audit_with_pending_lighthouse1)).to eq(false)
      expect(audits.include?(@successful_audit1)).to eq(true)
    end

    it 'returns the correct audits when include_pending_lighthouse_audits: true and include_failed_lighthouse_audits: true' do
      audits = @script_subscriber.audits_by_script_change(@script_change, include_pending_lighthouse_audits: true, include_failed_lighthouse_audits: true)
      expect(audits.include?(@audit_with_failed_lighthouse1)).to eq(true)
      expect(audits.include?(@audit_with_pending_lighthouse1)).to eq(true)
      expect(audits.include?(@successful_audit1)).to eq(true)
    end

    it 'returns the correct audits when include_pending_lighthouse_audits: true and include_failed_lighthouse_audits: false' do
      audits = @script_subscriber.audits_by_script_change(@script_change, include_pending_lighthouse_audits: true, include_failed_lighthouse_audits: false)
      expect(audits.include?(@audit_with_failed_lighthouse1)).to eq(false)
      expect(audits.include?(@audit_with_pending_lighthouse1)).to eq(true)
      expect(audits.include?(@successful_audit1)).to eq(true)
    end
  end

  describe '#validations' do
    it 'validates_uniqueness_of script_id scoped by domain_id' do
      script_subscriber_2 = build(:script_subscriber, domain: @domain, script: @script)
      script_subscriber_3 = build(:script_subscriber, domain: @domain_2, script: @script)
      expect(script_subscriber_2.valid?).to eq(false)
      expect(script_subscriber_3.valid?).to eq(true)
    end
  end
end
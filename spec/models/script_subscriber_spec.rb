require 'rails_helper'

RSpec.describe Tag, type: :model do
  before(:each) do
    stub_script_valid_url_validation
    @domain = create(:domain)
    @domain_2 = create(:domain_2)
    @script = create(:script)
    @tag_version = create(:tag_version, script: @script)
    @tag = create(:tag, domain: @domain, script: @script)
    execution_reason = create(:manual_execution)

    @audit_with_pending_lighthouse1 = create(:audit_with_pending_lighthouse, 
      tag_version: @tag_version, 
      tag: @tag, 
      execution_reason: execution_reason,
      created_at: DateTime.now - 1.day
    )
    @audit_with_failed_lighthouse1 = create(:audit_with_failed_lighthouse, 
      tag_version: @tag_version, 
      tag: @tag, 
      execution_reason: execution_reason,
      created_at: DateTime.now - 2.days
    )
    @successful_audit1= create(:audit, 
      tag_version: @tag_version, 
      tag: @tag, 
      execution_reason: execution_reason,
      created_at: DateTime.now - 3.days
    )

    @audit_with_pending_lighthouse2 = create(:audit_with_pending_lighthouse, 
      tag_version: @tag_version, 
      tag: @tag, 
      execution_reason: execution_reason,
      created_at: DateTime.now - 2.days
    )
    @audit_with_failed_lighthouse2 = create(:audit_with_failed_lighthouse, 
      tag_version: @tag_version, 
      tag: @tag, 
      execution_reason: execution_reason,
      created_at: DateTime.now - 3.days
    )
    @successful_audit2 = create(:audit, 
      tag_version: @tag_version, 
      tag: @tag, 
      execution_reason: execution_reason,
      created_at: DateTime.now - 4.days
    )
  end

  describe '#most_recent_audit_by_tag_version' do
    it 'returns the the most recent completed, successful lighthouse audit' do
      most_recent_audit = @tag.most_recent_audit_by_tag_version(@tag_version)
      expect(most_recent_audit).to eq(@successful_audit1)
    end

    it 'returns the the most recent successful OR unsuccesful lighthouse audit' do
      most_recent_audit = @tag.most_recent_audit_by_tag_version(@tag_version, include_failed_lighthouse_audits: true)
      expect(most_recent_audit).to eq(@audit_with_failed_lighthouse1)
    end

    it 'returns the the most recent pending OR incomplete lighthouse audit' do
      most_recent_audit = @tag.most_recent_audit_by_tag_version(@tag_version, include_pending_lighthouse_audits: true)
      expect(most_recent_audit).to eq(@audit_with_pending_lighthouse1)
    end

    it 'returns the the most recent pending OR failed audit' do
      most_recent_audit = @tag.most_recent_audit_by_tag_version(@tag_version, include_pending_lighthouse_audits: true, include_failed_lighthouse_audits: true)
      expect(most_recent_audit).to eq(@audit_with_pending_lighthouse1)
    end
  end

  describe '#audits_by_tag_version' do
    it 'returns only completed, successful audits without arguments' do
      audits = @tag.audits_by_tag_version(@tag_version)
      expect(audits.include?(@audit_with_failed_lighthouse1)).to eq(false)
      expect(audits.include?(@audit_with_pending_lighthouse1)).to eq(false)
      expect(audits.include?(@successful_audit1)).to eq(true)
    end

    it 'returns the correct audits when include_pending_lighthouse_audits: false and include_failed_lighthouse_audits: false' do
      audits = @tag.audits_by_tag_version(@tag_version, include_pending_lighthouse_audits: false, include_failed_lighthouse_audits: false)
      expect(audits.include?(@audit_with_failed_lighthouse1)).to eq(false)
      expect(audits.include?(@audit_with_pending_lighthouse1)).to eq(false)
      expect(audits.include?(@successful_audit1)).to eq(true)
    end

    it 'returns the correct audits when include_pending_lighthouse_audits: false and include_failed_lighthouse_audits: true' do
      audits = @tag.audits_by_tag_version(@tag_version, include_pending_lighthouse_audits: false, include_failed_lighthouse_audits: true)
      expect(audits.include?(@audit_with_failed_lighthouse1)).to eq(true)
      expect(audits.include?(@audit_with_pending_lighthouse1)).to eq(false)
      expect(audits.include?(@successful_audit1)).to eq(true)
    end

    it 'returns the correct audits when include_pending_lighthouse_audits: true and include_failed_lighthouse_audits: true' do
      audits = @tag.audits_by_tag_version(@tag_version, include_pending_lighthouse_audits: true, include_failed_lighthouse_audits: true)
      expect(audits.include?(@audit_with_failed_lighthouse1)).to eq(true)
      expect(audits.include?(@audit_with_pending_lighthouse1)).to eq(true)
      expect(audits.include?(@successful_audit1)).to eq(true)
    end

    it 'returns the correct audits when include_pending_lighthouse_audits: true and include_failed_lighthouse_audits: false' do
      audits = @tag.audits_by_tag_version(@tag_version, include_pending_lighthouse_audits: true, include_failed_lighthouse_audits: false)
      expect(audits.include?(@audit_with_failed_lighthouse1)).to eq(false)
      expect(audits.include?(@audit_with_pending_lighthouse1)).to eq(true)
      expect(audits.include?(@successful_audit1)).to eq(true)
    end
  end

  describe '#validations' do
    it 'validates_uniqueness_of script_id scoped by domain_id' do
      tag_2 = build(:tag, domain: @domain, script: @script)
      tag_3 = build(:tag, domain: @domain_2, script: @script)
      expect(tag_2.valid?).to eq(false)
      expect(tag_3.valid?).to eq(true)
    end

    it 'does not allow for more active script subcriptions than the organization maximum_active_tags' do
      @domain.organization.update_column :maximum_active_tags, 1

      new_script = create(:script, url: "www.123.com")
      new_tag = build(:tag, script: new_script, domain: @domain)
      expect(new_tag.valid?).to eq(false)
      expect(new_tag.errors.full_messages).to eq(["Cannot activate tag. Your plan only allows for 1 active monitored tags."])
    end
  end
end
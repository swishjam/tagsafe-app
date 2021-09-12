require 'rails_helper'

RSpec.describe PerformanceAudit, type: :model do
  before(:each) do
    prepare_test!
    tag = create(:tag, domain: @domain)
    create(:tag_preference, tag: tag)
    tag_version = create(:tag_version, tag: tag)
    @audit = create(:pending_audit, tag: tag, tag_version: tag_version, execution_reason: ExecutionReason.MANUAL)
    @performance_audit = create(:individual_performance_audit_with_tag, audit: @audit)
  end

  describe '#completed!' do
    it 'sets the completed_at timestamp' do
      expect(@performance_audit.completed_at).to be(nil)
      @performance_audit.completed!
      expect(@performance_audit.completed_at).to_not be(nil)
    end

    it 'does not call AfterAuditsIndividualPerformanceAuditsCompletedJob if Audit `performance_audit_failed?` returns true and `all_individual_performance_audits_completed?` returns true' do
      allow(@audit).to receive(:performance_audit_failed?).and_return(true)
      allow(@audit).to receive(:all_individual_performance_audits_completed?).and_return(true)
      expect(AfterAuditsIndividualPerformanceAuditsCompletedJob).to_not receive(:perform_later)
      @performance_audit.completed!
    end

    it 'does not call AfterAuditsIndividualPerformanceAuditsCompletedJob if Audit `performance_audit_failed?` returns false and `all_individual_performance_audits_completed?` returns false' do
      allow(@audit).to receive(:performance_audit_failed?).and_return(false)
      allow(@audit).to receive(:all_individual_performance_audits_completed?).and_return(false)
      expect(AfterAuditsIndividualPerformanceAuditsCompletedJob).to_not receive(:perform_later)
      @performance_audit.completed!
    end

    it 'does not call AfterAuditsIndividualPerformanceAuditsCompletedJob if Audit `performance_audit_failed?` returns true and `all_individual_performance_audits_completed?` returns false' do
      allow(@audit).to receive(:performance_audit_failed?).and_return(true)
      allow(@audit).to receive(:all_individual_performance_audits_completed?).and_return(false)
      expect(AfterAuditsIndividualPerformanceAuditsCompletedJob).to_not receive(:perform_later)
      @performance_audit.completed!
    end


    it 'calls AfterAuditsIndividualPerformanceAuditsCompletedJob if Audit `performance_audit_failed?` returns false and `all_individual_performance_audits_completed?` returns true' do
      allow(@audit).to receive(:performance_audit_failed?).and_return(false)
      allow(@audit).to receive(:all_individual_performance_audits_completed?).and_return(true)
      expect(AfterAuditsIndividualPerformanceAuditsCompletedJob).to receive(:perform_later).exactly(:once)
      @performance_audit.completed!
    end
  end
end
require 'rails_helper'

RSpec.describe PerformanceAuditManager::DeltaPerformanceAuditCreator do
  before(:each) do
    prepare_test!
    tag = create(:tag, domain: @container)
    tag_preference = create(:tag_preference, tag: tag, performance_audit_iterations: 1)
    @tag_version = create(:tag_version, tag: tag)
    @audit = create(:pending_audit, tag: tag, tag_version: @tag_version, performance_audit_iterations: 1, execution_reason: ExecutionReason.MANUAL)

    @individual_perf_audit_without_tag_results = {
      dom_complete: rand(50..100),
      dom_interactive: rand(40..90),
      first_contentful_paint: rand(20..80),
      script_duration: rand(20..50),
      layout_duration: rand(20..50),
      task_duration: rand(20..50)
    }
    @individual_perf_audit_with_tag_results = {
      dom_complete: @individual_perf_audit_without_tag_results[:dom_complete]*rand(0..100)/100.0+1,
      dom_interactive: @individual_perf_audit_without_tag_results[:dom_complete]*rand(0..100)/100.0+1,
      first_contentful_paint: @individual_perf_audit_without_tag_results[:dom_complete]*rand(0..100)/100.0+1,
      script_duration: @individual_perf_audit_without_tag_results[:dom_complete]*rand(0..100)/100.0+1,
      layout_duration: @individual_perf_audit_without_tag_results[:dom_complete]*rand(0..100)/100.0+1,
      task_duration: @individual_perf_audit_without_tag_results[:dom_complete]*rand(0..100)/100.0+1
    }

    create(:individual_performance_audit_with_tag, @individual_perf_audit_with_tag_results.merge(audit: @audit, enqueued_at: 5.minutes.ago, completed_at: 1.minute.ago))
    create(:individual_performance_audit_without_tag, @individual_perf_audit_without_tag_results.merge(audit: @audit, enqueued_at: 5.minutes.ago, completed_at: 1.minute.ago))

    @expected_delta_results = {}
    %i[dom_complete dom_interactive first_contentful_paint script_duration layout_duration task_duration].each do |attr|
      @expected_delta_results[attr] = expected_delta_value(attr)
    end
    
    @creator = PerformanceAuditManager::DeltaPerformanceAuditCreator.new(@audit)
  end

  def expected_delta_value(attr)
    value = (@individual_perf_audit_with_tag_results[attr] - @individual_perf_audit_without_tag_results[attr]).to_f.round(2)
    value < 0 ? 0.0 : value
  end

  describe '#create_delta_audit!' do
    it 'creates a DeltaPerformanceAudit on the Audit with correct values' do
      expect(@audit.preferred_delta_performance_audit).to be(nil)
      @creator.create_delta_audit!
      @audit.reload
      expect(@audit.preferred_delta_performance_audit).to_not be(nil)
      expect(@audit.preferred_delta_performance_audit.dom_complete).to be(@expected_delta_results[:dom_complete])
      expect(@audit.preferred_delta_performance_audit.dom_interactive).to be(@expected_delta_results[:dom_interactive])
      expect(@audit.preferred_delta_performance_audit.first_contentful_paint).to be(@expected_delta_results[:first_contentful_paint])
      expect(@audit.preferred_delta_performance_audit.script_duration).to be(@expected_delta_results[:script_duration])
      expect(@audit.preferred_delta_performance_audit.layout_duration).to be(@expected_delta_results[:layout_duration])
      expect(@audit.preferred_delta_performance_audit.layout_duration).to be(@expected_delta_results[:layout_duration])
    end
  end

  describe '#tagsafe_score_from_delta_results' do
    it 'calls score! on the TagsafeScorer with the correct arguments' do
      expect(TagsafeScorer).to receive(:new).with(
        @expected_delta_results.merge(byte_size: @tag_version.bytes)
      ).exactly(:once).and_call_original
      expect_any_instance_of(TagsafeScorer).to receive(:score!).exactly(:once)
      @creator.send(:tagsafe_score_from_delta_results, @expected_delta_results)
    end
  end

  describe '#median_individual_audit_with_tag' do
    before(:each) { @audit.individual_performance_audits.destroy_all }
    it 'returns audit\'s median PerformanceAuditWithTag by TagSafe score when theres 3 indiviual performance audits' do
      first_individual_audit_with_tag = create(:individual_performance_audit_with_tag, audit: @audit, tagsafe_score: 10)
      second_individual_audit_with_tag = create(:individual_performance_audit_with_tag, audit: @audit, tagsafe_score: 12)
      third_individual_audit_with_tag = create(:individual_performance_audit_with_tag, audit: @audit, tagsafe_score: 14)
  
      creator = PerformanceAuditManager::DeltaPerformanceAuditCreator.new(@audit)

      expect(creator.send(:median_individual_audit_with_tag)).to eq(second_individual_audit_with_tag)
    end

    it 'returns audit\'s median PerformanceAuditWithTag by TagSafe score when theres 5 indiviual performance audits' do
      fifth_individual_audit_with_tag = create(:individual_performance_audit_with_tag, audit: @audit, tagsafe_score: 18)
      first_individual_audit_with_tag = create(:individual_performance_audit_with_tag, audit: @audit, tagsafe_score: 10)
      third_individual_audit_with_tag = create(:individual_performance_audit_with_tag, audit: @audit, tagsafe_score: 14)
      fourth_individual_audit_with_tag = create(:individual_performance_audit_with_tag, audit: @audit, tagsafe_score: 16)
      second_individual_audit_with_tag = create(:individual_performance_audit_with_tag, audit: @audit, tagsafe_score: 12)
  
      creator = PerformanceAuditManager::DeltaPerformanceAuditCreator.new(@audit)

      expect(creator.send(:median_individual_audit_with_tag)).to eq(third_individual_audit_with_tag)
    end

    it 'returns Audit\'s median (the lowest of the two medians) PerformanceAuditWithTag by TagSafe score when theres 4 indiviual performance audits' do
      second_individual_audit_with_tag = create(:individual_performance_audit_with_tag, audit: @audit, tagsafe_score: 12)
      fourth_individual_audit_with_tag = create(:individual_performance_audit_with_tag, audit: @audit, tagsafe_score: 16)
      third_individual_audit_with_tag = create(:individual_performance_audit_with_tag, audit: @audit, tagsafe_score: 14)
      first_individual_audit_with_tag = create(:individual_performance_audit_with_tag, audit: @audit, tagsafe_score: 10)
  
      creator = PerformanceAuditManager::DeltaPerformanceAuditCreator.new(@audit)

      expect(creator.send(:median_individual_audit_with_tag)).to eq(second_individual_audit_with_tag)
    end
    
    it 'returns audit\'s median (the lowest of the two medians) PerformanceAuditWithTag by TagSafe score when theres 8 indiviual performance audits' do
      third_individual_audit_with_tag = create(:individual_performance_audit_with_tag, audit: @audit, tagsafe_score: 14)
      first_individual_audit_with_tag = create(:individual_performance_audit_with_tag, audit: @audit, tagsafe_score: 10)
      second_individual_audit_with_tag = create(:individual_performance_audit_with_tag, audit: @audit, tagsafe_score: 12)
      eigth_individual_audit_with_tag = create(:individual_performance_audit_with_tag, audit: @audit, tagsafe_score: 24)
      sixth_individual_audit_with_tag = create(:individual_performance_audit_with_tag, audit: @audit, tagsafe_score: 20)
      fourth_individual_audit_with_tag = create(:individual_performance_audit_with_tag, audit: @audit, tagsafe_score: 16)
      fifth_individual_audit_with_tag = create(:individual_performance_audit_with_tag, audit: @audit, tagsafe_score: 18)
      seventh_individual_audit_with_tag = create(:individual_performance_audit_with_tag, audit: @audit, tagsafe_score: 22)
  
      creator = PerformanceAuditManager::DeltaPerformanceAuditCreator.new(@audit)

      expect(creator.send(:median_individual_audit_with_tag)).to eq(fourth_individual_audit_with_tag)
    end
  end

  describe '#median_individual_audit_without_tag' do
    before(:each) { @audit.individual_performance_audits.destroy_all }
    it 'returns audit\'s median PerformanceAuditWithoutTag by TagSafe score when theres 3 indiviual performance audits' do
      first_individual_audit_with_tag = create(:individual_performance_audit_without_tag, audit: @audit, tagsafe_score: 10)
      second_individual_audit_with_tag = create(:individual_performance_audit_without_tag, audit: @audit, tagsafe_score: 12)
      third_individual_audit_with_tag = create(:individual_performance_audit_without_tag, audit: @audit, tagsafe_score: 14)
  
      creator = PerformanceAuditManager::DeltaPerformanceAuditCreator.new(@audit)

      expect(creator.send(:median_individual_audit_without_tag)).to eq(second_individual_audit_with_tag)
    end

    it 'returns audit\'s median PerformanceAuditWithTag by TagSafe score when theres 5 indiviual performance audits' do
      fifth_individual_audit_with_tag = create(:individual_performance_audit_without_tag, audit: @audit, tagsafe_score: 18)
      first_individual_audit_with_tag = create(:individual_performance_audit_without_tag, audit: @audit, tagsafe_score: 10)
      third_individual_audit_with_tag = create(:individual_performance_audit_without_tag, audit: @audit, tagsafe_score: 14)
      fourth_individual_audit_with_tag = create(:individual_performance_audit_without_tag, audit: @audit, tagsafe_score: 16)
      second_individual_audit_with_tag = create(:individual_performance_audit_without_tag, audit: @audit, tagsafe_score: 12)
  
      creator = PerformanceAuditManager::DeltaPerformanceAuditCreator.new(@audit)

      expect(creator.send(:median_individual_audit_without_tag)).to eq(third_individual_audit_with_tag)
    end

    it 'returns audit\'s median PerformanceAuditWithTag by TagSafe score when theres 4 indiviual performance audits' do
      second_individual_audit_with_tag = create(:individual_performance_audit_without_tag, audit: @audit, tagsafe_score: 12)
      fourth_individual_audit_with_tag = create(:individual_performance_audit_without_tag, audit: @audit, tagsafe_score: 16)
      third_individual_audit_with_tag = create(:individual_performance_audit_without_tag, audit: @audit, tagsafe_score: 14)
      first_individual_audit_with_tag = create(:individual_performance_audit_without_tag, audit: @audit, tagsafe_score: 10)
  
      creator = PerformanceAuditManager::DeltaPerformanceAuditCreator.new(@audit)

      expect(creator.send(:median_individual_audit_without_tag)).to eq(second_individual_audit_with_tag)
    end
    
    it 'returns audit\'s median PerformanceAuditWithTag by TagSafe score when theres 8 indiviual performance audits' do
      third_individual_audit_with_tag = create(:individual_performance_audit_without_tag, audit: @audit, tagsafe_score: 14)
      first_individual_audit_with_tag = create(:individual_performance_audit_without_tag, audit: @audit, tagsafe_score: 10)
      second_individual_audit_with_tag = create(:individual_performance_audit_without_tag, audit: @audit, tagsafe_score: 12)
      eigth_individual_audit_with_tag = create(:individual_performance_audit_without_tag, audit: @audit, tagsafe_score: 24)
      sixth_individual_audit_with_tag = create(:individual_performance_audit_without_tag, audit: @audit, tagsafe_score: 20)
      fourth_individual_audit_with_tag = create(:individual_performance_audit_without_tag, audit: @audit, tagsafe_score: 16)
      fifth_individual_audit_with_tag = create(:individual_performance_audit_without_tag, audit: @audit, tagsafe_score: 18)
      seventh_individual_audit_with_tag = create(:individual_performance_audit_without_tag, audit: @audit, tagsafe_score: 22)
  
      creator = PerformanceAuditManager::DeltaPerformanceAuditCreator.new(@audit)

      expect(creator.send(:median_individual_audit_without_tag)).to eq(fourth_individual_audit_with_tag)
    end
  end
end
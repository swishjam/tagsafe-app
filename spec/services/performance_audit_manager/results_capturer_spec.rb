require 'rails_helper'

RSpec.describe PerformanceAuditManager::ResultsCapturer do
  before(:each) do
    prepare_test!
    tag = create(:tag, domain: @container)
    tag_preference = create(:tag_preference, tag: tag)
    tag_version = create(:tag_version, tag: tag)
    url_to_audit = create(:url_to_audit, tag: tag, display_url: @container.url, audit_url: @container.url)
    audit = create(:audit, 
      execution_reason: ExecutionReason.MANUAL,
      enqueued_at: 10.minutes.ago,
      tag: tag, 
      tag_version: tag_version, 
      audited_url: url_to_audit,
      performance_audit_iterations: 2
    )
    @individual_performance_audit = create(:individual_performance_audit_with_tag, audit: audit, enqueued_at: 5.minutes.ago, completed_at: nil)
    @individual_performance_audit_2 = create(:individual_performance_audit_with_tag, audit: audit, enqueued_at: 5.minutes.ago, completed_at: nil)
    
    @evaluator = PerformanceAuditManager::ResultsCapturer.new(
      individual_performance_audit: @individual_performance_audit, 
      results: { 'DOMComplete' => 100, 'DOMContentLoaded' => 100, 'DOMInteractive' => 100, 'FirstContentfulPaint' => 100, 'LayoutDuration' => 100, 'ScriptDuration' => 100, 'TaskDuration' => 100 },
      logs: 'Logz go here :)',
      error: nil,
      blocked_resources: ['https://www.blocked.com'],
      page_load_trace_json_url: []
    )

    @failed_evaluator = PerformanceAuditManager::ResultsCapturer.new(
      individual_performance_audit: @individual_performance_audit_2, 
      results: { 'DOMComplete' => 100, 'DOMContentLoaded' => 100, 'DOMInteractive' => 100, 'FirstContentfulPaint' => 100, 'LayoutDuration' => 100, 'ScriptDuration' => 100, 'TaskDuration' => 100 },
      logs: 'Logz go here :)',
      error: 'Oops! an error occurred.',
      blocked_resources: ['https://www.blocked.com'],
      page_load_trace_json_url: []
    )
  end

  describe '#capture_results!' do
    it 'updates the IndividualPerformanceAudit with the audit results when an error is not present' do
      expect(@evaluator).to_not receive(:update_individual_performance_audits_results!)
      expect(@evaluator).to receive(:update_individual_performance_audits_results!).exactly(:once)
      @evaluator.capture_results!
    end

    it 'fails the IndividualPerformanceAudit when an error is present' do
      expect(@failed_evaluator).to receive(:update_individual_performance_audits_results!).exactly(:once)
      # expect(@individual_performance_audit_2).to receive(:error!).exactly(:once)
      expect(@failed_evaluator).to_not receive(:update_individual_performance_audits_results!)

      @failed_evaluator.capture_results!
    end
  end

  describe 'update_individual_performance_audits_results_for_successful_audit!' do
    it 'updates the IndividualPerformanceAudit with the audit results' do
      @evaluator.send(:update_individual_performance_audits_results!)
      
      @individual_performance_audit.reload
      expect(@individual_performance_audit.dom_complete).to eq(100)
      expect(@individual_performance_audit.dom_content_loaded).to eq(100)
      expect(@individual_performance_audit.dom_interactive).to eq(100)
      expect(@individual_performance_audit.first_contentful_paint).to eq(100)
      expect(@individual_performance_audit.script_duration).to eq(100)
      expect(@individual_performance_audit.layout_duration).to eq(100)
      expect(@individual_performance_audit.task_duration).to eq(100)
      expect(@individual_performance_audit.tagsafe_score).to_not eq(nil)
      expect(@individual_performance_audit.performance_audit_log.logs).to eq('Logz go here :)')
    end
  end
  
  describe '#update_individual_performance_audits_results_for_failed_audit!' do
    it 'updates the IndividualPerformanceAudit with an error message and all metrics to -1' do
      @failed_evaluator.capture_results!
      @individual_performance_audit_2.reload
      expect(@individual_performance_audit_2.dom_complete).to eq(100)
      expect(@individual_performance_audit_2.dom_interactive).to eq(100)
      expect(@individual_performance_audit_2.first_contentful_paint).to eq(100)
      expect(@individual_performance_audit_2.script_duration).to eq(100)
      expect(@individual_performance_audit_2.layout_duration).to eq(100)
      expect(@individual_performance_audit_2.task_duration).to eq(100)
      expect(@individual_performance_audit_2.tagsafe_score).to eq(nil)
      expect(@individual_performance_audit_2.performance_audit_log.logs).to eq('Logz go here :)')
      expect(@individual_performance_audit_2.audit.reload.error_message).to_not eq(nil)
      expect(@individual_performance_audit_2.reload.error_message).to_not eq('Oops! an error occurred!')
    end
  end

  describe '#calculate_tagsafe_score_for_performance_audit' do
    it 'initializes a TagsafeScorer and calls score!' do
      expect(TagsafeScorer).to receive(:new).with({
        dom_complete: 100,
        dom_content_loaded: 100,
        dom_interactive: 100,
        first_contentful_paint: 100,
        layout_duration: 100,
        script_duration: 100,
        task_duration: 100,
        byte_size: @individual_performance_audit.audit.tag_version.bytes
      }).exactly(:once).and_call_original
      expect_any_instance_of(TagsafeScorer).to receive(:score!).exactly(:once)
      @evaluator.send(:calculate_tagsafe_score_for_performance_audit)
    end
  end
end
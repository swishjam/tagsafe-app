require 'rails_helper'

RSpec.describe PerformanceAuditManager::AuditPrecisionScorer do
  before(:each) do
    prepare_test!
    tag = create(:tag, domain: @domain)
    url_to_audit = create(:url_to_audit, tag: tag, audit_url: 'https://www.google.com', display_url: 'https://www.google.com', tagsafe_hosted: false)
    tag_preference = create(:tag_preference, tag: tag, performance_audit_iterations: 1)
    @tag_version = create(:tag_version, tag: tag)
    @audit = create(:audit, tag: tag, tag_version: @tag_version, audited_url: url_to_audit, execution_reason: ExecutionReason.MANUAL)
  end

  describe '#calculate_precision' do
    it 'generates a precision score of 0 when the performance audits had the same exact results' do
      perf_audit_args = { audit_id: @audit.id, dom_complete: 5, dom_interactive: 10, first_contentful_paint: 12, script_duration: 15, layout_duration: 20, task_duration: 25 }
      perf_audit_with_tag_1 = create(:individual_performance_audit_with_tag, perf_audit_args)
      perf_audit_with_tag_2 = create(:individual_performance_audit_with_tag, perf_audit_args)
      perf_audit_without_tag_1 = create(:individual_performance_audit_without_tag, perf_audit_args)
      perf_audit_without_tag_2 = create(:individual_performance_audit_without_tag, perf_audit_args)

      precision_scorer = PerformanceAuditManager::AuditPrecisionScorer.new(@audit)
      precision = precision_scorer.calculate_variance_precision
    end

    it 'generates a bad score when scores range dramatically' do
      create(:individual_performance_audit_with_tag, audit_id: @audit.id, dom_complete: 1_000, dom_interactive: 1_500, first_contentful_paint: 500, script_duration: 300, layout_duration: 100, task_duration: 200)
      create(:individual_performance_audit_with_tag, audit_id: @audit.id, dom_complete: 1_500, dom_interactive: 3_000, first_contentful_paint: 750, script_duration: 400, layout_duration: 150, task_duration: 250)
      create(:individual_performance_audit_with_tag, audit_id: @audit.id, dom_complete: 1_700, dom_interactive: 2_000, first_contentful_paint: 850, script_duration: 500, layout_duration: 250, task_duration: 250)
      create(:individual_performance_audit_with_tag, audit_id: @audit.id, dom_complete: 1_200, dom_interactive: 2_500, first_contentful_paint: 250, script_duration: 400, layout_duration: 250, task_duration: 450)
      create(:individual_performance_audit_with_tag, audit_id: @audit.id, dom_complete: 2_000, dom_interactive: 3_000, first_contentful_paint: 950, script_duration: 600, layout_duration: 350, task_duration: 200)


      create(:individual_performance_audit_without_tag, audit_id: @audit.id, dom_complete: 2_000, dom_interactive: 2_000, first_contentful_paint: 1_000, script_duration: 500, layout_duration: 200, task_duration: 150)
      create(:individual_performance_audit_without_tag, audit_id: @audit.id, dom_complete: 2_400, dom_interactive: 3_000, first_contentful_paint: 1_500, script_duration: 400, layout_duration: 300, task_duration: 250)
      create(:individual_performance_audit_without_tag, audit_id: @audit.id, dom_complete: 2_200, dom_interactive: 2_400, first_contentful_paint: 1_600, script_duration: 700, layout_duration: 250, task_duration: 350)
      create(:individual_performance_audit_without_tag, audit_id: @audit.id, dom_complete: 3_000, dom_interactive: 2_600, first_contentful_paint: 1_300, script_duration: 600, layout_duration: 300, task_duration: 150)
      create(:individual_performance_audit_without_tag, audit_id: @audit.id, dom_complete: 2_900, dom_interactive: 3_000, first_contentful_paint: 1_900, script_duration: 900, layout_duration: 400, task_duration: 200)
      
      precision_scorer = PerformanceAuditManager::AuditPrecisionScorer.new(@audit)
      score = precision_scorer.calculate_variance_precision
    end
  end
end
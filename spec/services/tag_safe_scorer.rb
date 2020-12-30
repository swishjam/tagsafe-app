require 'rails_helper'

RSpec.describe TagSafeScorer do
  before(:each) do
    stub_geppetto_communication
    create_execution_reasons
    create_performance_audit_metric_types
    script = create(:script)
    domain = create(:domain)
    script_change = create(:script_change, script: script, bytes: 100_000)
    script_subscriber = create(:script_subscriber, script: script, domain: domain, first_script_change: script_change)
    audit = create(:audit, script_change: script_change, script_subscriber: script_subscriber, execution_reason: ExecutionReason.MANUAL)
    @delta_performance_audit = create(:delta_performance_audit, audit: audit)
    @performance_audit_with_tag = create(:performance_audit_with_tag, audit: audit)
    dom_complete_metric = create(:performance_audit_metric, 
      performance_audit: @delta_performance_audit, 
      performance_audit_metric_type: PerformanceAuditMetricType.by_key('DOMComplete').first, 
      result: 4_950
    )
    dom_interactive_metric = create(:performance_audit_metric, 
      performance_audit: @delta_performance_audit, 
      performance_audit_metric_type: PerformanceAuditMetricType.by_key('DOMInteractive').first, 
      result: 500
    )
    first_contentful_paint_metric = create(:performance_audit_metric, 
      performance_audit: @delta_performance_audit, 
      performance_audit_metric_type: PerformanceAuditMetricType.by_key('FirstContentfulPaint').first, 
      result: 50
    )
    @scorer = TagSafeScorer.new(@delta_performance_audit)
  end

  describe '#record_score!' do
    it 'creates the TagSafe performance audit metric with the correct score' do
      expect(@delta_performance_audit.metric_result('TagSafeScore')).to be(nil)
      @scorer.record_score!
      expect(@delta_performance_audit.metric_result('TagSafeScore')).to be(66.0)
    end

    it 'raises an InvalidPerformanceAudit error if it is not a DeltaPerformanceAudit' do
      expect{ TagSafeScorer.new(@performance_audit_with_tag).record_score! }.to raise_error(TagSafeScorer::InvalidPerformanceAudit)
    end
  end

  describe '#score!' do
    it 'returns the TagSafe score' do
      expect(@scorer.send(:score!)).to eq(66)
    end
  end

  describe '#dom_complete_deduction' do
    it 'calculates correctly' do
      expect(@scorer.send(:dom_complete_deduction)).to eq(29.7)
    end
  end

  describe '#dom_complete_deduction' do
    it 'calculates correctly' do
      expect(@scorer.send(:dom_interactive_deduction)).to eq(3)
    end
  end

  describe '#dom_complete_deduction' do
    it 'calculates correctly' do
      expect(@scorer.send(:first_contentful_paint_deduction)).to eq(0.3)
    end
  end

  describe '#byte_size_deduction' do
    it 'calculates correctly' do
      expect(@scorer.send(:byte_size_deduction)).to eq(1)
    end
  end
end


# DOM Complete
# + 5.02 seconds
# DOM Interactive
# + 526 ms
# First Contentful Paint
# + 540 ms
# Task Duration Time
# + 4.41 ms
# Script Duration
# + 4.37 ms
# Layout Duration
# 0 ms
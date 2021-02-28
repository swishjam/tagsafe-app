class DeltaPerformanceAudit < PerformanceAudit
  has_one :script_subscriber_audits_chart_data

  def score_impact(metric)
    scorer.performance_metric_deduction(metric)
  end

  private

  def scorer
    @scorer ||= TagSafeScorer.new(self)
  end
end
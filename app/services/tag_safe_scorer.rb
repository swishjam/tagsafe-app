class TagSafeScorer
  DEFAULT_WEIGHTS = {
    'DOMComplete' => 1,
    'DOMInteractive' => 0.75,
    'FirstContentfulPaint' => 0.6
  }
  def initialize(performance_audit)
    @performance_audit = performance_audit
  end

  def record_score!
    PerformanceAuditMetric.create(
      result: score!, 
      performance_audit: @performance_audit, 
      performance_audit_metric_type: tagsafe_score_metric_type
    )
  end

  private
  def score!
    @performance_audit.performance_audit_metrics
  end

  def tagsafe_score_metric_type
    @tagsafe_score_metric_type ||= PerformanceAuditMetricType.find_by!(key: 'TagSafeScore')
  end
end
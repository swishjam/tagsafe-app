class TagSafeScorer
  class InvalidPerformanceAudit < StandardError; end;
  DEFAULT_WEIGHTS = {
    'DOMComplete' => 0.3,
    'DOMInteractive' => 0.3,
    'FirstContentfulPaint' => 0.3,
    # 'LayoutDuration' => 0.1,
    # 'ScriptDuration' => 0.1,
    # 'TaskDuration' => 0.1,
    'Bytes' => 0.1
  }

  # deduct 1 point of 100 for each metric: Impact Score / METRIC_SCORE_INCREMENTS
  # a DOMComplete impact of 100ms would be a deduction of 2 points
  METRIC_SCORE_INCREMENTS = {
    'DOMComplete' => 50,
    'DOMInteractive' => 50,
    'FirstContentfulPaint' => 50,
    'Bytes' => 10_000
  }

  def initialize(delta_performance_audit)
    @delta_performance_audit = delta_performance_audit
    @starting_score = 100
  end

  def record_score!
    raise InvalidPerformanceAudit unless @delta_performance_audit.is_a?(DeltaPerformanceAudit)
    PerformanceAuditMetric.create(
      result: score!, 
      performance_audit: @delta_performance_audit, 
      performance_audit_metric_type: tagsafe_score_metric_type
    )
  end

  private

  def score!
    @starting_score - dom_complete_deduction - dom_interactive_deduction - first_contentful_paint_deduction - byte_size_deduction
  end

  def dom_complete_deduction
    performance_metric_deduction('DOMComplete')
  end

  def dom_interactive_deduction
    performance_metric_deduction('DOMInteractive')
  end

  def first_contentful_paint_deduction
    performance_metric_deduction('FirstContentfulPaint')
  end

  def performance_metric_deduction(metric_key)
    (@delta_performance_audit.metric_result(metric_key)/METRIC_SCORE_INCREMENTS[metric_key]) * DEFAULT_WEIGHTS[metric_key]
  end

  def byte_size_deduction
    (@delta_performance_audit.audit.script_change.bytes/METRIC_SCORE_INCREMENTS['Bytes']) * DEFAULT_WEIGHTS['Bytes']
  end

  def tagsafe_score_metric_type
    @tagsafe_score_metric_type ||= PerformanceAuditMetricType.find_by!(key: 'TagSafeScore')
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
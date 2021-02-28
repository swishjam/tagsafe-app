class TagSafeScorer
  class InvalidPerformanceAudit < StandardError; end;
  DEFAULT_WEIGHTS = {
    dom_complete: 0.3,
    dom_interactive: 0.15,
    first_contentful_paint: 0.15,
    layout_duration: 0.1,
    task_duration: 0.1,
    script_duration: 0.1,
    bytes: 0.1
  }

  # deduct n points of 100 for each metric: Impact Score / METRIC_SCORE_INCREMENTS
  # a DOMComplete impact of 100ms would be a deduction of 2 points
  METRIC_SCORE_INCREMENTS = {
    dom_complete: 15,
    dom_interactive: 15,
    first_contentful_paint: 15,
    task_duration: 0.005,
    layout_duration: 0.005,
    script_duration: 0.005,
    bytes: 10_000
  }

  def initialize(delta_performance_audit)
    @delta_performance_audit = delta_performance_audit
  end

  def record_score!
    raise InvalidPerformanceAudit unless @delta_performance_audit.is_a?(DeltaPerformanceAudit)
    @delta_performance_audit.update!(tagsafe_score: score)
  end

  def score
    100 - 
      performance_metric_deduction(:dom_complete) - 
      performance_metric_deduction(:dom_interactive) - 
      performance_metric_deduction(:first_contentful_paint) - 
      performance_metric_deduction(:task_duration) -
      performance_metric_deduction(:script_duration) -
      performance_metric_deduction(:layout_duration) -
      byte_size_deduction
  end

  def performance_metric_deduction(metric_key)
    deduction = (@delta_performance_audit[metric_key]/METRIC_SCORE_INCREMENTS[metric_key]) * DEFAULT_WEIGHTS[metric_key]
    deduction > DEFAULT_WEIGHTS[metric_key]*100 ? DEFAULT_WEIGHTS[metric_key]*100 : deduction
  end

  def byte_size_deduction
    deduction = (@delta_performance_audit.audit.script_change.bytes/METRIC_SCORE_INCREMENTS[:bytes]) * DEFAULT_WEIGHTS[:bytes]
    deduction > DEFAULT_WEIGHTS[:bytes]*100 ? DEFAULT_WEIGHTS[:bytes]*100 : deduction
  end
end
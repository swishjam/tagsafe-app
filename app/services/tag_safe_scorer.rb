class TagSafeScorer
  class InvalidPerformanceAudit < StandardError; end;
  DEFAULT_WEIGHTS = {
    dom_complete: 0.4,
    dom_interactive: 0.4,
    first_contentful_paint: 0.2,
    # 'LayoutDuration' => 0.1,
    # 'ScriptDuration' => 0.1,
    # 'TaskDuration' => 0.1,
    bytes: 0.1
  }

  # deduct 1 point of 100 for each metric: Impact Score / METRIC_SCORE_INCREMENTS
  # a DOMComplete impact of 100ms would be a deduction of 2 points
  METRIC_SCORE_INCREMENTS = {
    dom_complete: 25,
    dom_interactive: 12.5,
    first_contentful_paint: 25,
    bytes: 10_000
  }

  def initialize(delta_performance_audit)
    @delta_performance_audit = delta_performance_audit
    @starting_score = 100
  end

  def record_score!
    raise InvalidPerformanceAudit unless @delta_performance_audit.is_a?(DeltaPerformanceAudit)
    @delta_performance_audit.update!(tagsafe_score: score!)
  end

  private

  def score!
    @starting_score - dom_complete_deduction - dom_interactive_deduction - first_contentful_paint_deduction - byte_size_deduction
  end

  def dom_complete_deduction
    performance_metric_deduction(:dom_complete)
  end

  def dom_interactive_deduction
    performance_metric_deduction(:dom_interactive)
  end

  def first_contentful_paint_deduction
    performance_metric_deduction(:first_contentful_paint)
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
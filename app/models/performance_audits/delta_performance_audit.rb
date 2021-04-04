class DeltaPerformanceAudit < PerformanceAudit
  def score_impact(metric_key)
    scorer.performance_metric_deduction(metric_key)
  end

  private

  # decorate the model because it's not a column for score_impact
  def byte_size
    audit.tag_version.bytes
  end

  def scorer
    @scorer ||= TagSafeScorer.new(
      dom_complete: dom_complete,
      dom_interactive: dom_interactive,
      first_contentful_paint: first_contentful_paint,
      task_duration: task_duration,
      script_duration: script_duration,
      layout_duration: layout_duration,
      byte_size: audit.tag_version.bytes
    )
  end
end
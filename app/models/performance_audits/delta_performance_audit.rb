class DeltaPerformanceAudit < PerformanceAudit
  def score_impact(metric_key)
    scorer.performance_metric_deduction(send(metric_key), metric_key)
  end

  private

  def scorer
    @scorer ||= TagSafeScorer.new(
      dom_complete: dom_complete,
      dom_interactive: dom_interactive,
      first_contentful_paint: first_contentful_paint,
      task_duration: task_duration,
      script_duration: script_duration,
      layout_duration: layout_duration,
      byte_size: audit.script_change.bytes
    )
  end
end
class DeltaPerformanceAudit < PerformanceAudit
  TAGSAFE_SCORE_THRESHOLDS = {
    good: 90,
    warn: 80
  }

  after_create :completed!

  validate :valid_individual_performance_audits

  def completed!
    touch(:enqueued_at, :completed_at)
  end
  
  private

  # decorate the model because it's not a column for score_impact
  def byte_size
    audit.tag_version.bytes
  end

  def scorer
    @scorer ||= TagSafeScorer.new(
      performance_audit_calculator: audit.tag.domain.current_performance_audit_calculator,
      dom_complete: dom_complete,
      dom_content_loaded: dom_content_loaded,
      dom_interactive: dom_interactive,
      first_contentful_paint: first_contentful_paint,
      task_duration: task_duration,
      script_duration: script_duration,
      layout_duration: layout_duration,
      byte_size: audit.tag_version.bytes
    )
  end

  def valid_individual_performance_audits
    unless audit.all_individual_performance_audits_completed?
      errors.add(:base, "Cannot create DeltaPerformanceAudit unless the Audit has successfully completed all #{audit.performance_audit_iterations*2} Performance Audits")
    end
  end
end
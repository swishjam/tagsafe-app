class DeltaPerformanceAudit < PerformanceAudit
  TAGSAFE_SCORE_THRESHOLDS = {
    good: 90,
    warn: 80
  }

  after_create :completed!
  after_create_commit { audit.tag_version.update_tag_version_content }
  after_update_commit { audit.tag_version.update_tag_version_content }
  after_create_commit { audit.tag.update_tag_content }
  after_update_commit { audit.tag.update_tag_content }

  validate :valid_individual_performance_audits

  def completed!
    touch(:enqueued_at, :completed_at)
    audit.delta_performance_audit_completed!
  end

  def score_impact(metric_key)
    scorer.performance_metric_deduction(metric_key)
  end

  def performance_audit_with_tag_for_calculation
    audit.performance_audit_with_tag_for_calculation
  end

  private

  # decorate the model because it's not a column for score_impact
  def byte_size
    audit.tag_version.bytes
  end

  def scorer
    @scorer ||= TagSafeScorer.new(
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
      errors.add(:base, 'Cannot create DeltaPerformanceAudit when there are failed or pending IndividualPerformanceAudits')
    end
  end
end
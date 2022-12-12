class AverageDeltaPerformanceAudit < DeltaPerformanceAudit
  scope :billable_for_container, -> (container) { includes(:audit).where.not(tagsafe_score: nil).where(audit: container.audits.billable) }
end
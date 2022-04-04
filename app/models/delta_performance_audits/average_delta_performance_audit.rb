class AverageDeltaPerformanceAudit < DeltaPerformanceAudit
  scope :billable_for_domain, -> (domain) { includes(:audit).where.not(tagsafe_score: nil).where(audit: domain.audits.billable) }
end
class AverageDeltaPerformanceAudit < DeltaPerformanceAudit
  scope :billable_for_domain, -> (domain) { includes(:audit).where.not(tagsafe_score: nil, audit_id: nil).where(audit: { domain_id: domain.id }) }
end
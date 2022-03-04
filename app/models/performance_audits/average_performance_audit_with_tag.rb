class AveragePerformanceAuditWithTag < PerformanceAudit
  has_one :delta_performance_audit, foreign_key: :performance_audit_with_tag_id
end
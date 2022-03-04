class AveragePerformanceAuditWithoutTag < PerformanceAudit
  has_one :delta_performance_audit, foreign_key: :performance_audit_without_tag_id
end
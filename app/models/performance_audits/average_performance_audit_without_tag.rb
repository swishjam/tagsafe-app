class AveragePerformanceAuditWithoutTag < PerformanceAudit
  uid_prefix 'apawot'
  has_one :delta_performance_audit, foreign_key: :performance_audit_without_tag_id
end
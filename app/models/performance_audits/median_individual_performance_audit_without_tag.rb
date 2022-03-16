class MedianIndividualPerformanceAuditWithoutTag < PerformanceAudit
  uid_prefix 'mipawot'
  has_one :delta_performance_audit, foreign_key: :performance_audit_without_tag_id
end
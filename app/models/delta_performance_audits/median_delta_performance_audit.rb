class MedianDeltaPerformanceAudit < DeltaPerformanceAudit
  # belongs_to :median_performance_audit_with_tag, foreign_key: :performance_audit_with_tag_id, class_name: 'MedianPerformanceAudit'
  # belongs_to :median_performance_audit_without_tag, foreign_key: :performance_audit_without_tag_id, class_name: 'MedianPerformanceAudit'
end
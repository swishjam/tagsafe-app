class AverageDeltaPerformanceAudit < DeltaPerformanceAudit
  # belongs_to :average_performance_audit_with_tag, foreign_key: :performance_audit_with_tag_id, class_name: AveragePerformanceAudit.to_s
  # belongs_to :average_performance_audit_without_tag, foreign_key: :performance_audit_without_tag_id, class_name: AveragePerformanceAudit.to_s
end
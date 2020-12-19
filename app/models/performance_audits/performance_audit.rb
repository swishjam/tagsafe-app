class PerformanceAudit < ApplicationRecord
  belongs_to :audit
  has_many :performance_audit_metrics
  has_one :performance_audit_logs, class_name: 'PerformanceAuditLog'

  def metric_result(metric_key)
    performance_audit_metrics.by_key(metric_key).first.result.round(2)
  end
end
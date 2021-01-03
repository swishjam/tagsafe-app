class PerformanceAudit < ApplicationRecord
  belongs_to :audit
  has_many :performance_audit_metrics
  has_one :performance_audit_logs, class_name: 'PerformanceAuditLog'

  scope :most_recent, -> { joins(audit: :script_change).where(script_changes: { most_recent: true })}
  scope :primary_audits, -> { joins(:audit).where(audits: { primary: true }) }
  scope :by_script_subscriber_ids, -> (script_subscriber_ids) { joins(:audit).where(audits: { script_subscriber_id: script_subscriber_ids })}

  def metric_result(metric_key, include_units: false)
    metric = performance_audit_metrics.by_key(metric_key).first
    include_units ? "#{metric&.result&.round(2)} #{metric.unit_abbrev}": metric&.result&.round(2)
  end

  def previous_metric_result(metric_key)
    return nil if audit.previous_primary_audit.nil?
    audit.previous_primary_audit.performance_audits.find_by(type: type).metric_result(metric_key).round(2)
  end

  def change_in_metric(metric_key)
    return nil if audit.previous_primary_audit.nil?
    (metric_result(metric_key) - previous_metric_result(metric_key)).round(2)
  end

  def percent_change_in_metric(metric_key)
    return nil if audit.previous_primary_audit.nil?
    ((change_in_metric(metric_key)/previous_metric_result(metric_key))*100).round(2)
  end
end
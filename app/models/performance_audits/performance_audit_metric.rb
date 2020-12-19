class PerformanceAuditMetric < ApplicationRecord
  belongs_to :performance_audit
  belongs_to :performance_audit_metric_type

  scope :by_key, -> (key) { includes(:performance_audit_metric_type).where(performance_audit_metric_types: { key: key })}
  scope :by_script_subscriber, -> (script_subscriber) { includes(performance_audit: [:audit]).where(performance_audits: { audits: { script_subscriber_id: script_subscriber.id}}) }
  scope :primary_audits, -> { includes(performance_audit: [:audit]).where(performance_audits: { audits: { primary: true }}) }
  scope :by_audit_type, -> (performance_audit_type) { includes(:performance_audit).where(performance_audits: { type: performance_audit_type} ) }

  def title
    performance_audit_metric_type.title
  end

  def key
    performance_audit_metric_type.key
  end

  def unit
    performance_audit_metric_type.unit
  end
end
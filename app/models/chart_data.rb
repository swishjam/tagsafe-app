class ChartData < ApplicationRecord
  belongs_to :audit

  scope :by_peformance_audit_type, -> (audit_type) { includes(audit: :performance_audit).where(performance_audit: { type: by_peformance_audit_type }) }
  scope :by_script_subscriber_id, -> (script_subscriber_id) { joins(:audit).where(audits: { script_subscriber_id: script_subscriber_id }) }
  scope :due_to_script_change, -> { where(due_to_script_change: true) }

  def self.update_new_primary_audit(new_primary_audit:, previous_primary_audit:)
    previous_chart_data = ChartData.find(audit: previous_primary_audit)
    if previous_chart_data
      previous_chart_data.update(audit: new_primary_audit)
    else
      Rails.logger.warn "No chart data to update for previous primary audit: #{previous_primary_audit&.id}. \
                          Creating chart data from scratch for #{new_primary_audit.script_change.created_at} \ 
                          timestamp with audit #{new_primary_audit.id}."
      ChartData.create(audit: new_primary_audit, timestamp: new_primary_audit.script_change.created_at)
    end
  end

  def performance_audit_metric_result(metric_key, audit_type = :delta_performance_audit)
    audit.send(audit_type)&.performance_audit_metrics.by_key(metric_key)&.first&.result
  end
end
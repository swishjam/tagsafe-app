class MovePerformanceAuditMetricsToPerformanceAudit < ActiveRecord::Migration[5.2]
  def change
    drop_table :performance_audit_metrics
    drop_table :performance_audit_metric_types
    add_column :performance_audits, :dom_complete, :float
    add_column :performance_audits, :dom_interactive, :float
    add_column :performance_audits, :first_contentful_paint, :float
    add_column :performance_audits, :script_duration, :float
    add_column :performance_audits, :layout_duration, :float
    add_column :performance_audits, :task_duration, :float
    add_column :performance_audits, :tagsafe_score, :float
  end
end

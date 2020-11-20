class ChangeLighthouseAuditResultMetricToFloat < ActiveRecord::Migration[5.2]
  def change
    change_column :lighthouse_audit_result_metrics, :result, :float
    change_column :lighthouse_audit_result_metrics, :score, :float
    add_column :lighthouse_audit_result_metrics, :result_metric, :string
  end
end
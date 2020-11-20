class CreateLighthouseAuditResultMetricType < ActiveRecord::Migration[5.2]
  def change
    create_table :lighthouse_audit_result_metric_types do |t|
      t.string :title
      t.string :key
      t.string :result_unit
    end
    add_column :lighthouse_audit_result_metrics, :lighthouse_audit_result_metric_type_id, :integer
    remove_column :lighthouse_audit_result_metrics, :title
    remove_column :lighthouse_audit_result_metrics, :name
    remove_column :lighthouse_audit_result_metrics, :result_metric
  end
end

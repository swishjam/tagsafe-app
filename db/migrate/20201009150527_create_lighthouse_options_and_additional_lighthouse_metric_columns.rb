class CreateLighthouseOptionsAndAdditionalLighthouseMetricColumns < ActiveRecord::Migration[5.2]
  def change
    add_column :tags, :run_lighthouse_audit, :boolean, default: true
    add_column :lighthouse_audit_result_metrics, :result_metric, :string
    add_column :lighthouse_audit_result_metrics, :title, :string
  end
end

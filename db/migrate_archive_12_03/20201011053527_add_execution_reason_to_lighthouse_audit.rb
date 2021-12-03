class AddExecutionReasonToLighthouseAudit < ActiveRecord::Migration[5.2]
  def change
    rename_table :test_execution_reasons, :execution_reasons
    rename_column :test_group_runs, :test_execution_reason_id, :execution_reason_id
    add_column :lighthouse_audits, :execution_reason_id, :integer
  end
end

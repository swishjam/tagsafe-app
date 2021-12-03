class AddTestExecutionReasonToTestGroupRuns < ActiveRecord::Migration[5.2]
  def change
    add_column :test_group_runs, :test_execution_reason_id, :integer
    remove_column :test_runs, :test_execution_reason_id
  end
end

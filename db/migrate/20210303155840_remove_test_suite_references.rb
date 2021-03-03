class RemoveTestSuiteReferences < ActiveRecord::Migration[5.2]
  def change
    remove_column :audits, :test_suite_enqueued_at
    remove_column :audits, :test_suite_completed_at
    drop_table :tests
    drop_table :test_group_runs
    drop_table :test_result_subscribers
    drop_table :test_subscribers
    drop_table :expected_test_results
  end
end

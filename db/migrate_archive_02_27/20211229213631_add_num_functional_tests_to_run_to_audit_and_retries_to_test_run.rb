class AddNumFunctionalTestsToRunToAuditAndRetriesToTestRun < ActiveRecord::Migration[6.1]
  def up
    add_column :audits, :num_functional_tests_to_run, :integer
    add_column :test_runs, :test_run_id_retried_from, :integer
    add_index :test_runs, :test_run_id_retried_from
  end

  def down
    remove_column :audits, :num_functional_tests_to_run
    remove_column :test_runs, :test_run_id_retried_from
  end
end

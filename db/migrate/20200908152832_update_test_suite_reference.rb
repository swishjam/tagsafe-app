class UpdateTestSuiteReference < ActiveRecord::Migration[5.2]
  def change
    remove_column :test_runs, :test_suite_id
    add_column :test_runs, :test_suite_run_id, :integer
  end
end

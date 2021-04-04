class AddTagVersionIdToTestRun < ActiveRecord::Migration[5.2]
  def change
    remove_column :test_runs, :test_suite_run_id
    drop_table :test_suite_runs
    add_column :test_runs, :tag_version_id, :integer
  end
end

class ChangeTestRunWithTagRelationship < ActiveRecord::Migration[6.1]
  def up
    remove_column :test_runs, :test_run_without_tag_id
    add_reference :test_runs, :original_test_run_with_tag
  end

  def down
    add_reference :test_runs, :test_run_without_tag
    remove_column :test_runs, :original_test_run_with_tag_id
  end
end

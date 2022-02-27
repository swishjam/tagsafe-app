class AddErrorAttributesToTestRun < ActiveRecord::Migration[6.1]
  def up
    add_column :test_runs, :error_message, :string
    add_column :test_runs, :error_type, :string
    add_column :test_runs, :error_trace, :text
  end

  def down
    remove_column :test_runs, :error_message
    remove_column :test_runs, :error_type
    remove_column :test_runs, :error_trace
  end
end

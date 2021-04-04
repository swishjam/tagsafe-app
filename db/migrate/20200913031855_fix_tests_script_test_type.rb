class FixTestsTagTestType < ActiveRecord::Migration[5.2]
  def change
    rename_column :test_runs, :script_test_type, :script_test_type_id
  end
end

class CreateTestGroupRuns < ActiveRecord::Migration[5.2]
  def change
    create_table :test_group_runs do |t|
      t.references :test_subscriber
      t.references :script_change
      t.boolean :passed
      t.timestamps
    end

    add_column :test_runs, :test_group_run_id, :integer
  end
end

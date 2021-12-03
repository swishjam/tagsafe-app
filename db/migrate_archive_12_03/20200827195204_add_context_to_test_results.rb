class AddContextToTestResults < ActiveRecord::Migration[5.2]
  def change
    create_table :test_execution_reasons do |t|
      t.string :name
    end

    add_column :test_results, :test_execution_reason_id, :integer
    add_column :test_results, :created_at, :timestamp 
  end
end

class CreateTestSuiteRunsAndTestRunsTables < ActiveRecord::Migration[5.2]
  def change
    create_table :test_suite_runs do |t|
      t.references :test_execution_reason
      t.references :domain
      t.references :script_change
      t.boolean :passed
      t.timestamp :created_at
    end

    create_table :test_runs do |t|
      t.references :test_execution_reason
      t.references :domain
      t.references :test
      t.references :test_suite
      t.boolean :passed
      t.mediumtext :results
      t.timestamp :created_at
    end

    drop_table :test_results
    drop_table :test_failures
  end
end

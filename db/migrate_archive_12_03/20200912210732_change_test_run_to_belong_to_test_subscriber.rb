class ChangeTestRunToBelongToTestSubscriber < ActiveRecord::Migration[5.2]
  def change
    remove_column :test_runs, :test_id
    remove_column :test_runs, :domain_id
    add_column :test_runs, :test_subscriber_id, :integer
    drop_table :scripts_tests
  end
end

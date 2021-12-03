class CreateExpectedTestResults < ActiveRecord::Migration[5.2]
  def change
    add_column :test_subscribers, :expected_test_result_id, :integer

    create_table :expected_test_results do |t|
      t.string :expected_result
      t.string :operator
      t.string :data_type
    end
  end
end

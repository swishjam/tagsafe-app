class CreateTestFailures < ActiveRecord::Migration[5.2]
  def change
    create_table :test_failures do |t|
      t.references :test_result
      t.string :failure_message
      t.timestamp :created_at
    end
  end
end

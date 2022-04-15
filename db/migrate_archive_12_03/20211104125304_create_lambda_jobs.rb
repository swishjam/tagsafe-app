class CreateLambdaJobs < ActiveRecord::Migration[6.1]
  def change
    create_table :executed_step_functions do |t|
      t.string :uid
      t.references :parent, polymorphic: true
      t.string :function_name
      t.text :request_payload
      t.longtext :response_payload
      t.integer :response_code
      t.timestamps
    end
  end
end

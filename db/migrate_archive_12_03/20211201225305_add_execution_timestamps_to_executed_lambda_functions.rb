class AddExecutionTimestampsToExecutedLambdaFunctions < ActiveRecord::Migration[6.1]
  def change
    add_column :executed_lambda_functions, :executed_at, :datetime
    add_column :executed_lambda_functions, :completed_at, :datetime
    remove_column :executed_lambda_functions, :created_at
    remove_column :executed_lambda_functions, :updated_at
  end
end

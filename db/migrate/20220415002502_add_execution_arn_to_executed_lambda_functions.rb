class AddExecutionArnToExecutedLambdaFunctions < ActiveRecord::Migration[6.1]
  def up
    # add_column :executed_step_functions, :step_function_execution_arn, :string
    # add_column :executed_step_functions, :step_function_execution_name, :string
    # remove_column :executed_step_functions, :function_name
    # rename_table :executed_step_functions, :executed_step_functions
  end
end

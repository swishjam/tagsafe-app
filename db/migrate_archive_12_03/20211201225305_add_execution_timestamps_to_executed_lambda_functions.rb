class AddExecutionTimestampsToExecutedStepFunctions < ActiveRecord::Migration[6.1]
  def change
    add_column :executed_step_functions, :executed_at, :datetime
    add_column :executed_step_functions, :completed_at, :datetime
    remove_column :executed_step_functions, :created_at
    remove_column :executed_step_functions, :updated_at
  end
end

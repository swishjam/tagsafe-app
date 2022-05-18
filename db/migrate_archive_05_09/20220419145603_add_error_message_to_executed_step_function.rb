class AddErrorMessageToExecutedStepFunction < ActiveRecord::Migration[6.1]
  def up
    add_column :executed_step_functions, :error_message, :text
  end
end

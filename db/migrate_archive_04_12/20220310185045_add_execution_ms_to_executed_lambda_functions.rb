class AddExecutionMsToExecutedStepFunctions < ActiveRecord::Migration[6.1]
  def up
    add_column :executed_step_functions, :ms_to_receive_response, :float
    add_column :audits, :has_confident_tagsafe_score, :boolean
  end
end

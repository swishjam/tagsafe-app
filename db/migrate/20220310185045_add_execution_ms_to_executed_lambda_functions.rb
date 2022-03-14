class AddExecutionMsToExecutedLambdaFunctions < ActiveRecord::Migration[6.1]
  def up
    add_column :executed_lambda_functions, :ms_to_receive_response, :float
    add_column :audits, :has_confident_tagsafe_score, :boolean
  end
end

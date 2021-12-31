module Admin
  class ExecutedLambdaFunctionsController < BaseController
    def for_obj
      @executed_lambda_function = ExecutedLambdaFunction.find_by(parent_type: params[:parent_type], parent_id: params[:parent_id])
      @object = @executed_lambda_function.parent
    end
  end
end
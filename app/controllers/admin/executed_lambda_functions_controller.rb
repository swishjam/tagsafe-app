module Admin
  class ExecutedLambdaFunctionsController < BaseController
    def index
      @pending_lambda_functions = ExecutedLambdaFunction.includes(:parent)
                                                          .pending
                                                          .most_recent_last(timestamp_column: :executed_at)
                                                          .page(params[:page] || 1).per(params[:per_page] || 25)
    end

    def for_obj
      @executed_lambda_function = ExecutedLambdaFunction.find_by(parent_type: params[:parent_type], parent_id: params[:parent_id])
      @object = @executed_lambda_function.parent
    end
  end
end
module Admin
  class ExecutedLambdaFunctionsController < BaseController
    def index
      @pending_lambda_functions = ExecutedLambdaFunction.includes(:parent)
                                                          .pending
                                                          .most_recent_last(timestamp_column: :executed_at)
                                                          .page(params[:page] || 1).per(params[:per_page] || 25)
    end

    def show
      @executed_lambda_function = ExecutedLambdaFunction.includes(:parent).find(params[:id])
      logs_retriever = CloudwatchLogsRetriever.new(@executed_lambda_function)
      @lambda_function_cloudwatch_logs = logs_retriever.retrieve_logs
      @send_to_tagsafe_lambda_function_cloudwatch_logs = logs_retriever.retrieve_send_to_tagsafe_lambda_function_logs
      @send_to_tagsafe_event_bus_cloudwatch_logs = logs_retriever.retrieve_send_to_tagsafe_event_bus_logs
    end

    def for_obj
      @executed_lambda_function = ExecutedLambdaFunction.find_by(parent_type: params[:parent_type], parent_id: params[:parent_id])
      @object = @executed_lambda_function.parent
    end
  end
end
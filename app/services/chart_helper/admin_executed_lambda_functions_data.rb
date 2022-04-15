module ChartHelper
  class AdminExecutedStepFunctionsData
    def initialize(start_time: 1.day.ago, end_time: Time.now)
      @start_time = start_time
      @end_time = end_time
    end
    
    def chart_data
      [
        pending_lambda_functions,
        completed_lambda_functions,
        total_lambda_functions,
        avg_lambda_response_time
        # potentially_never_responded_lambda_functions
      ]
    end

    private

    def pending_lambda_functions
      {
        name: 'Pending Lambda Functions',
        data: ExecutedStepFunction.pending.group_by_minute(:executed_at, n: 5, range: @start_time..@end_time).count
      }
    end

    def completed_lambda_functions
      {
        name: 'Completed Lambda Functions',
        data: ExecutedStepFunction.completed.group_by_minute(:executed_at, n: 5, range: @start_time..@end_time).count
      }
    end

    def total_lambda_functions
      {
        name: 'Total Lambda Functions',
        data: ExecutedStepFunction.completed.group_by_minute(:executed_at, n: 5, range: @start_time..@end_time).count
      }
    end

    def avg_lambda_response_time
      {
        name: 'Average Lambda Execution Time',
        data: ExecutedStepFunction.completed.group_by_minute(:executed_at, n: 5, range: @start_time..@end_time).average(:ms_to_receive_response)
      }
    end

    # def potentially_never_responded_lambda_functions
    #   {
    #     name: 'Potentially Never Responded Lambda Functions',
    #     data: ExecutedStepFunction.potentially_never_responded.group_by_minute(:executed_at, n: 5, range: @start_time..@end_time).count
    #   }
    # end
  end
end
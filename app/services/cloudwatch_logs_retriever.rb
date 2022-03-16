class CloudwatchLogsRetriever
  def initialize(executed_lambda_function)
    @executed_lambda_function = executed_lambda_function
  end

  def retrieve_logs
    if @executed_lambda_function.aws_log_stream_name
      retrieve_completed_lambda_logs
    else
      retrieve_in_flight_lambda_logs_based_on_uid(@executed_lambda_function.aws_log_group_name)
    end
  end

  def retrieve_send_to_tagsafe_event_bus_logs
    retrieve_in_flight_lambda_logs_based_on_uid(ExecutedLambdaFunction::CloudWatchLogGroups.SEND_TO_REDIS_EVENT_BUS)
  end

  def retrieve_send_to_tagsafe_lambda_function_logs
    retrieve_in_flight_lambda_logs_based_on_uid(ExecutedLambdaFunction::CloudWatchLogGroups.SEND_TO_REDIS_LAMBDA_FUNCTION)
  end

  private

  def retrieve_completed_lambda_logs
    TagsafeAws::CloudWatch.get_log_events_in_stream(@executed_lambda_function.aws_log_stream_name, 
      log_group_name: @executed_lambda_function.aws_log_group_name
    )
  end

  def retrieve_in_flight_lambda_logs_based_on_uid(log_group)
    initial_cloudwatch_log_by_executed_lambda_function_uid = TagsafeAws::CloudWatch.search_log_group_for_events(log_group,
      start_time: Time.at(@executed_lambda_function.executed_at), 
      filter_pattern: @executed_lambda_function.uid
    ).first
    return [] unless initial_cloudwatch_log_by_executed_lambda_function_uid
    TagsafeAws::CloudWatch.get_log_events_in_stream(initial_cloudwatch_log_by_executed_lambda_function_uid.log_stream_name, 
      log_group_name: log_group
    )
  end
end
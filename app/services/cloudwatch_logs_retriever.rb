class CloudwatchLogsRetriever
  def initialize(executed_step_function)
    @executed_step_function = executed_step_function
  end

  def retrieve_logs
    if @executed_step_function.aws_log_stream_name
      retrieve_completed_lambda_logs
    else
      retrieve_in_flight_lambda_logs_based_on_uid(@executed_step_function.aws_log_group_name)
    end
  end

  def retrieve_send_to_tagsafe_event_bus_logs
    retrieve_in_flight_lambda_logs_based_on_uid(ExecutedStepFunction::CloudWatchLogGroups.SEND_TO_REDIS_EVENT_BUS)
  end

  def retrieve_send_to_tagsafe_lambda_function_logs
    retrieve_in_flight_lambda_logs_based_on_uid(ExecutedStepFunction::CloudWatchLogGroups.SEND_TO_REDIS_LAMBDA_FUNCTION)
  end

  private

  def retrieve_completed_lambda_logs
    TagsafeAws::CloudWatch.get_log_events_in_stream(@executed_step_function.aws_log_stream_name, 
      log_group_name: @executed_step_function.aws_log_group_name
    )
  end

  def retrieve_in_flight_lambda_logs_based_on_uid(log_group)
    initial_cloudwatch_log_by_executed_step_function_uid = TagsafeAws::CloudWatch.search_log_group_for_events(log_group,
      start_time: Time.at(@executed_step_function.executed_at), 
      filter_pattern: @executed_step_function.uid
    ).first
    return [] unless initial_cloudwatch_log_by_executed_step_function_uid
    TagsafeAws::CloudWatch.get_log_events_in_stream(initial_cloudwatch_log_by_executed_step_function_uid.log_stream_name, 
      log_group_name: log_group
    )
  end
end
class IndividualPerformanceAuditWithTag < PerformanceAudit
  uid_prefix 'ipawt'
  after_update_commit { audit.update_completion_indicators }

  def state
    return 'completed' if success?
    return 'pending' if pending?
    return 'failed' if failed?
  end

  def cloudwatch_logs
    cloudwatch_client.get_log_events({
      log_group_name: "/aws/lambda/performance-auditer-#{ENV['LAMBDA_ENVIRONMENT'] || Rails.env}-runPerformanceAudit",
      log_stream_name: aws_log_stream_name,
      start_from_head: true,
      # start_time: enqueued_at.to_i,
      # end_time: completed_at.to_i
    }).events
  end

  def cloudwatch_client
    @cloudwatch_client ||= Aws::CloudWatchLogs::Client.new(
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
      region: 'us-east-1'
    )
  end
end
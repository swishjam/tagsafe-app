class IndividualPerformanceAudit < PerformanceAudit
  after_update_commit do
    broadcast_replace_to "#{audit_id}_completion_indicator", 
                          target: "#{audit_id}_completion_indicator", 
                          partial: 'audits/completion_indicator', 
                          locals: { audit: audit }
  end

  def state
    return 'completed' if success?
    return 'pending' if pending?
    return 'failed' if failed?
  end

  def cloudwatch_logs
    cloudwatch_client.get_log_events({
      log_group_name: "/aws/lambda/performance-auditer-#{ENV['LAMBDA_ENVIRONMENT'] || Rails.env}-runPerformanceAudit",
      log_stream_name: aws_log_stream_name,
      start_from_head: true
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
class IndividualPerformanceAuditWithoutTag < PerformanceAudit
  uid_prefix 'ipawot'
  has_one :delta_performance_audit, foreign_key: :performance_audit_without_tag_id

  def state
    return 'completed' if success?
    return 'pending' if pending?
    return 'failed' if failed?
  end

  def cloudwatch_logs
    self.class.cloudwatch_client.get_log_events({
      log_group_name: "/aws/lambda/performance-auditer-#{ENV['LAMBDA_ENVIRONMENT'] || Rails.env}-runPerformanceAudit",
      log_stream_name: executed_step_function.aws_log_stream_name,
      start_from_head: true,
      # start_time: enqueued_at.to_i,
      # end_time: completed_at.to_i
    }).events
  end

  def self.cloudwatch_client
    @cloudwatch_client ||= Aws::CloudWatchLogs::Client.new(
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
      region: 'us-east-1'
    )
  end
end
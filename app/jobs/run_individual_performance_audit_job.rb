class RunIndividualPerformanceAuditJob < ApplicationJob
  queue_as :performance_audit_runner_queue

  def perform(audit:, tag_version:, enable_tracing:, performance_audit_type:)
    lambda_sender = lambda_sender_class(performance_audit_type).new(audit: audit, tag_version: tag_version, enable_tracing: enable_tracing)
    response = lambda_sender.send!
    response_data = JSON.parse(response.payload.read)
    Rails.logger.info "Performance audit Lambda function completed.\nAudit #{audit.id}\nPerformance Audit: #{lambda_sender.individual_performance_audit.id}\n Response: #{response_data}"
    if response.status_code == 200 && response_data['errorMessage'].nil?
      SuccessfulLambdaFunctionReceiverJob.perform_now(response_data)
    else
      # TODO: this is linking the error to a successful performance audit?
      lambda_sender.individual_performance_audit.error!(response_data['errorMessage'] || response_data['error'])
    end
  end

  def lambda_sender_class(performance_audit_type)
    case performance_audit_type
    when :with_tag
      LambdaModerator::Senders::PerformanceAuditerWithTag
    when :without_tag
      LambdaModerator::Senders::PerformanceAuditerWithoutTag
    else
      raise StandardError, "Unrecognized `performance_audit_type` in RunIndividualPerformanceAuditJob: #{performance_audit_type}"
    end
  end
end
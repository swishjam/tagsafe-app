class RunIndividualPerformanceAuditJob < ApplicationJob
  queue_as :performance_audit_runner_queue

  def perform(audit:, tag_version:, lambda_sender_class:, enable_tracing:, include_page_load_resources:, inline_injected_script_tags:)
    lambda_sender = lambda_sender_class.new(
      audit: audit, 
      tag_version: tag_version, 
      enable_tracing: enable_tracing, 
      include_page_load_resources: include_page_load_resources,
      inline_injected_script_tags: inline_injected_script_tags
    )
    response = lambda_sender.send!
    if response.successful
      capture_successful_response(response.response_body, audit)
    else
      # TODO: this is linking the error to a successful performance audit?
      lambda_sender.individual_performance_audit.error!(response.error)
    end
  end

  def capture_successful_response(response_data, audit)
    PerformanceAuditManager::ResultsCapturer.new(
      individual_performance_audit_id: response_data['individual_performance_audit_id'], 
      results: response_data['results'], 
      blocked_tag_urls: response_data['blocked_tag_urls'], 
      allowed_tag_urls: response_data['allowed_tag_urls'],
      logs: response_data['logs'],
      aws_log_stream_name: response_data['aws_log_stream_name'],
      aws_request_id: response_data['aws_request_id'],
      aws_trace_id: response_data['aws_trace_id'],
      page_load_screenshot_urls: response_data['page_load_screenshot_urls'], 
      page_load_trace_json_url: response_data['page_load_trace_json_url'],
      error: response_data['error']
    ).capture_results!
    all_individual_performance_audit_completed = !audit.performance_audit_failed? && audit.all_individual_performance_audits_completed?
    if all_individual_performance_audit_completed
      audit.create_delta_performance_audit!
      audit.completed!
    end
  end
end
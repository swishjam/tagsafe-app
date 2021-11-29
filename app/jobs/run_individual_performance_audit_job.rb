class RunIndividualPerformanceAuditJob < ApplicationJob
  queue_as :performance_audit_runner_queue

  def perform(type:, audit:, tag_version:, options: {})
    performance_auditer = LambdaModerator::PerformanceAuditer.new(
      type: type,
      audit: audit, 
      tag_version: tag_version, 
      options: options
    )
    response = performance_auditer.send!
    if response.successful
      capture_successful_response(response.response_body, performance_auditer.individual_performance_audit, audit)
    else
      # TODO: I think this may be linking the error to a successful performance audit?
      # because an audit can have many failed performance audits we should change to generic errors
      performance_auditer.individual_performance_audit.error!(response.error)
    end
  end

  def capture_successful_response(response_data, individual_performance_audit, audit)
    PerformanceAuditManager::ResultsCapturer.new(
      individual_performance_audit: individual_performance_audit,
      results: response_data['results'], 
      blocked_resources: response_data['blocked_resources'],
      logs: response_data['logs'],
      page_load_screenshot_urls: response_data['page_load_screenshot_urls'], 
      page_load_trace_json_url: response_data['page_load_trace_json_url'],
      error: response_data['error'] || response_data['errorMessage']
    ).capture_results!
    all_individual_performance_audit_completed = !audit.failed? && audit.all_individual_performance_audits_completed?
    if all_individual_performance_audit_completed
      audit.create_delta_performance_audit!
      audit.completed!
    end
  end
end
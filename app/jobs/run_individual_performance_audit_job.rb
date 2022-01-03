class RunIndividualPerformanceAuditJob < ApplicationJob
  queue_as :performance_audit_runner_queue
  # queue_as do
  #   # determine if its part of the load of initial audits, put in onboarding_audits_queue ?
  # end
  
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
      performance_auditer.individual_performance_audit.error!(response.error)
    end
  end

  def capture_successful_response(response_data, individual_performance_audit, audit)
    PerformanceAuditManager::ResultsCapturer.new(
      individual_performance_audit: individual_performance_audit,
      results: response_data['results'], 
      puppeteer_recording: response_data['screen_recording'],
      blocked_resources: response_data['blocked_resources'],
      logs: response_data['logs'],
      error: response_data['error'] || response_data['errorMessage']
    ).capture_results!
    all_individual_performance_audit_completed = !audit.failed? && audit.all_individual_performance_audits_completed?
    if all_individual_performance_audit_completed
      audit.create_delta_performance_audit!
      audit.performance_audit_completed!
      audit.try_completion!
    end
  end
end
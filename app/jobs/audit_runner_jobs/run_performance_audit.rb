module AuditRunnerJobs
  class RunPerformanceAudit < ApplicationJob
    def perform(audit, options = {})
      # generate_cached_responses(audit) unless Util.env_is_true('DONT_CACHE_PERFORMANCE_AUDIT_RESPONSES')
      PerformanceAuditManager::QueueMaintainer.new(audit).run_next_set_of_performance_audits_or_mark_as_completed!
    end

    # def generate_cached_responses(audit, attempt_num = 1)
    #   response = LambdaFunctionInvoker::PerformanceAuditCacher.new(audit: audit, tag_version: audit.tag_version).send!
    #   if response.response_body['errorMessage'] || !response.successful
    #     if attempt_num <= 3
    #       generate_cached_responses(audit, attempt_num + 1)
    #     else
    #       audit.performance_audit_error!(response.response_body['errorMessage'] || response.error || "An unexpected error occurrred.")
    #     end
    #   else
    #     audit.performance_audit_configuration.update!(cached_responses_s3_url: response.response_body['cached_responses_s3_location'])
    #   end
    # end
  end
end
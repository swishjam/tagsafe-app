module AuditRunnerJobs
  class RunPerformanceAudit < ApplicationJob
    include RetriableJob
    queue_as :performance_audit_runner_queue

    DONT_CACHE_PERFORMANCE_AUDIT_RESPONSES = Util.env_is_true('DONT_CACHE_PERFORMANCE_AUDIT_RESPONSES')
    SHOULD_ENQUEUE_PERFORMANCE_AUDITS_SIMULTANEOUSLY = Util.env_is_true('ENQUEUE_INDIVIDUAL_PERFORMANCE_AUDITS_SIMULTANEOUSLY')
    NUM_SIMULTAENOUS_INDIVIDUAL_PERFORMANCE_AUDITS = (ENV['NUM_SIMULTAENOUS_INDIVIDUAL_PERFORMANCE_AUDITS'] || 1).to_i

    def perform(audit, options = {})
      generate_cached_responses(audit) unless DONT_CACHE_PERFORMANCE_AUDIT_RESPONSES
      if SHOULD_ENQUEUE_PERFORMANCE_AUDITS_SIMULTANEOUSLY
        NUM_SIMULTAENOUS_INDIVIDUAL_PERFORMANCE_AUDITS.times do
          audit.enqueue_next_performance_audit!(IndividualPerformanceAuditWithoutTag.SYMBOLIZED_AUDIT_TYPE)
          audit.enqueue_next_performance_audit!(IndividualPerformanceAuditWithTag.SYMBOLIZED_AUDIT_TYPE)
        end
      else
        audit.enqueue_next_performance_audit!(IndividualPerformanceAuditWithTag.SYMBOLIZED_AUDIT_TYPE)
      end
    end

    def generate_cached_responses(audit)
      response = LambdaModerator::PerformanceAuditCacher.new(audit: audit, tag_version: audit.tag_version).send!
      if response.response_body['errorMessage'] || !response.successful
        raise StandardError, response.response_body['errorMessage'] || response.error
      else
        audit.performance_audit_configuration.update!(cached_responses_s3_url: response.response_body['cached_responses_s3_location'])
      end
    end

    def self.on_retriable_job_failure(exception, audit, options = {})
      audit.performance_audit_error!(exception.message)
    end
  end
end
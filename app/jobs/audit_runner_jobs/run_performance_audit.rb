module AuditRunnerJobs
  class RunPerformanceAudit < ApplicationJob
    include RetriableJob
    queue_as :performance_audit_runner_queue
    NUM_SIMULTAENOUS_INDIVIDUAL_PERFORMANCE_AUDITS = (ENV['NUM_SIMULTAENOUS_INDIVIDUAL_PERFORMANCE_AUDITS'] || 1).to_i

    def perform(audit)
      generate_cached_responses(audit)
      NUM_SIMULTAENOUS_INDIVIDUAL_PERFORMANCE_AUDITS.times do
        audit.enqueue_next_individual_performance_audit_if_necessary!(:with_tag)
        audit.enqueue_next_individual_performance_audit_if_necessary!(:without_tag)
      end
    end

    def generate_cached_responses(audit)
      response = LambdaModerator::PerformanceAuditCacher.new(audit: audit, tag_version: audit.tag_version).send!
      if response.response_body['errorMessage'] || !response.successful
        raise StandardError, response.response_body['errorMessage'] || response.error
      else
        audit.update!(performance_audit_cached_responses_s3_url: response.response_body['cached_responses_s3_location'])
      end
    end

    def self.on_retriable_job_failure(exception, audit)
      audit.performance_audit_error!(exception.message)
    end
  end
end
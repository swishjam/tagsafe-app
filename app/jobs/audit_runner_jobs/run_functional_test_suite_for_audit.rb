module AuditRunnerJobs
  class RunFunctionalTestSuiteForAudit < ApplicationJob
    include RetriableJob
    queue_as :functional_tests_queue

    def perform(audit, options = {})
      ActiveRecord::Base.transaction do
        tests_to_run = audit.tag.functional_tests.enabled
        if tests_to_run.any?
          audit.tag.functional_tests.enabled.each{ |functional_test| functional_test.perform_test_run_with_tag_later!(associated_audit: audit) }
        else
          audit.audit.functional_tests_completed!
        end
      end
    end
  end
end
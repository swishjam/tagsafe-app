module AuditRunnerJobs
  class RunFunctionalTestSuiteForAudit < ApplicationJob
    def perform(audit, options = {})
      tests_to_run = audit.tag.functional_tests.enabled
      if tests_to_run.any?
        audit.tag.functional_tests.enabled.each{ |functional_test| functional_test.perform_test_run_with_tag_later!(associated_audit: audit) }
      else
        audit.functional_tests_completed!
      end
    end
  end
end
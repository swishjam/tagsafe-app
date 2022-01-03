class RunFunctionalTestSuiteForAuditJob < ApplicationJob
  queue_as :functional_tests_queue

  def perform(audit)
    audit.tag.functional_tests.enabled.each{ |functional_test| functional_test.perform_test_run_with_tag_now!(associated_audit: audit) }
    audit.functional_tests_completed!
    audit.try_completion!
  end
end
class RunFunctionalTestSuiteForAuditJob < ApplicationJob
  queue_as :functional_tests_queue

  def perform(audit)
    audit.tag.functional_tests.enabled.each{ |functional_test| functional_test.enqueue_test_run_with_tag!(associated_audit: audit) }
  end
end
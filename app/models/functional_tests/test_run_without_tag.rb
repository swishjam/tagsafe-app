class TestRunWithoutTag < TestRun
  uid_prefix 'trwot'
  belongs_to :audit
  belongs_to :original_test_run_with_tag, class_name: 'TestRunWithTag'

  def self.friendly_class_name
    'Test Run Without Tag'
  end

  def after_passed
    update_audit_functional_tests_completion_indicator(audit: audit, now: true)
    audit.functional_tests_completed! if audit.reload.completed_all_functional_tests?
  end

  def after_failed
    update_audit_functional_tests_completion_indicator(audit: audit, now: true)
    audit.functional_tests_completed! if audit.reload.completed_all_functional_tests?
  end
end
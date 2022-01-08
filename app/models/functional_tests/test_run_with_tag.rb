class TestRunWithTag < TestRun
  include Streamable
  belongs_to :audit
  has_one :follow_up_test_run_without_tag, class_name: 'TestRunWithoutTag', foreign_key: :original_test_run_with_tag_id
  has_one :test_run_without_tag, foreign_key: :original_test_run_with_tag_id

  scope :inconclusive, -> { joins(:follow_up_test_run_without_tag).with_tag.where(passed: false, follow_up_test_run_without_tag: { passed: false }) }
  scope :conclusive, -> { joins(:follow_up_test_run_without_tag).where(passed: false, follow_up_test_run_without_tag: { passed: true }).or(passed) }

  def self.friendly_class_name
    'Test Run With Tag'
  end

  def pending?
    passed.nil? || follow_up_test_run_without_tag&.pending?
  end

  def conclusive?
    passed? || (failed? && follow_up_test_run_without_tag&.passed?)
  end

  def inconclusive?
    failed? && follow_up_test_run_without_tag&.failed?
  end

  def retry!
    functional_test.perform_test_run_with_tag_later!(associated_audit: audit, test_run_retried_from: self)
  end

  def can_retry?
    true
  end

  def after_passed
    update_audit_test_run_row(test_run: self, now: true)
    update_audit_functional_tests_completion_indicator(audit: audit, now: true)
    # update_audit_table_row(audit: audit, now: true)
    # update_tag_version_table_row(tag_version: audit.tag_version, now: true)
    # update_tag_table_row(tag: audit.tag, now: true)
  end

  def after_failed
    functional_test.perform_test_run_without_tag_later!(original_test_run_with_tag: self)
    update_audit_test_run_row(test_run: self, now: true) 
    update_audit_functional_tests_completion_indicator(audit: audit, now: true)
    # update_audit_table_row(audit: audit, now: true)
    # update_tag_version_table_row(tag_version: audit.tag_version, now: true)
    # update_tag_table_row(tag: audit.tag, now: true)
  end
end
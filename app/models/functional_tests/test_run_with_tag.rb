class TestRunWithTag < TestRun
  belongs_to :audit
  has_one :follow_up_test_run_without_tag, class_name: 'TestRunWithoutTag', foreign_key: :original_test_run_with_tag_id

  def self.friendly_class_name
    'Test Run With Tag'
  end

  def conclusive?
    passed? || (failed? && follow_up_test_run_without_tag&.passed?)
  end

  def retry!
    functional_test.enqueue_test_run_with_tag!(associated_audit: audit, test_run_retried_from: self)
  end

  def can_retry?
    true
  end

  def after_failed
    follow_up_test_run_without_tag = functional_test.enqueue_test_run_without_tag!(original_test_run_with_tag: self)
  end
end
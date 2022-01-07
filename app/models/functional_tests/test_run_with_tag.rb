class TestRunWithTag < TestRun
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

  def after_failed
    follow_up_test_run_without_tag = functional_test.perform_test_run_without_tag_later!(original_test_run_with_tag: self)
  end
end
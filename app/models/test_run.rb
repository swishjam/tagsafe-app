class TestRun < ApplicationRecord
  belongs_to :test_subscriber, optional: true
  belongs_to :standalone_test_run_domain, class_name: 'Domain', primary_key: :standalone_test_run_domain_id, optional: true
  belongs_to :script_test_type
  belongs_to :test_group_run

  scope :failed, -> { where(passed: false) }
  scope :passed, -> { where(passed: true) }
  scope :current_tag, -> { where(script_test_type: ScriptTestType.CURRENT_TAG) }
  scope :previous_tag, -> { where(script_test_type: ScriptTestType.PREVIOUS_TAG) }
  scope :without_tag, -> { where(script_test_type: ScriptTestType.WITHOUT_TAG) }

  validate :has_correct_relations

  def evaluate_success!
    return passed unless passed.nil?
    update passed: did_pass?
    passed
  end

  def did_pass?
    test_subscriber.expected_test_result.passed?(results)
  end

  def result_status
    passed ? 'passed' : 'failed'
  end

  def test
    test_subscriber.test
  end

  def domain
    test_subscriber.domain
  end

  def script
    test_subscriber.script
  end

  ###############
  # VALIDATIONS #
  ###############
  def has_correct_relations
    errors[:base] << "Must have a test_subscriber or single_test_run_domain" unless test_subscriber.present? || standalone_test_run_domain.present?
  end
end
class TestRun < ApplicationRecord
  include Streamable
  include HasExecutedStepFunction
  # include IsReliantOnLambdaFunction
  
  belongs_to :functional_test
  belongs_to :test_run_retried_from, foreign_key: :test_run_id_retried_from, class_name: TestRun.to_s, optional: true
  has_many :retried_test_runs, foreign_key: :test_run_id_retried_from, class_name: TestRun.to_s
  has_one :puppeteer_recording, as: :initiator, dependent: :destroy
  accepts_nested_attributes_for :puppeteer_recording

  scope :completed, -> { where.not(passed: nil) }
  scope :pending, -> { where(passed: nil) }
  
  scope :passed, -> { where(passed: true) }
  scope :failed, -> { where(passed: false) }

  scope :retries, -> { where.not(test_run_id_retried_from: nil) }
  scope :not_retries, -> { where(test_run_id_retried_from: nil) }

  scope :with_tag, -> { where(type: 'TestRunWithTag') }
  scope :without_tag, -> { where(type: 'TestRunWithoutTag') }
  scope :dry_runs, -> { where(type: 'DryTestRun') }

  scope :conclusive, -> { all }
  scope :inconclusive, -> { none }

  def status
    pending? ? 'running' :
      passed? ? 'passed' : 'failed'
  end


  def passed!
    update!(passed: true)
    update_test_run_details_view(test_run: self, now: true)
    after_passed if respond_to?(:after_passed)
  end

  def failed!(message:, type: nil, trace: [])
    trace = [] unless ((trace || [])[0] || "").match(/-callableScript-[0-9]*\.js/)
    update!(passed: false, error_message: message, error_type: type, error_trace: trace.join("\n"))
    update_test_run_details_view(test_run: self, now: true)
    after_failed if respond_to?(:after_failed)
  end

  def completed?
    !pending?
  end

  def pending?
    passed.nil?
  end

  def passed?
    return false if pending?
    passed
  end

  def failed?
    return false if pending?
    !passed?
  end

  def conclusive?
    true
  end

  def inconclusive?
    !conclusive?
  end

  def can_retry?
    false
  end

  def is_retry?
    !test_run_id_retried_from.nil?
  end

  def full_error_message
    return error_message if error_trace.blank?
    "#{error_message}: #{error_trace}"
  end
end
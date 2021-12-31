class TestRun < ApplicationRecord
  belongs_to :functional_test
  belongs_to :test_run_retried_from, foreign_key: :test_run_id_retried_from, class_name: 'TestRun', optional: true
  has_many :retried_test_runs, foreign_key: :test_run_id_retried_from, class_name: 'TestRun'
  has_one :puppeteer_recording, as: :initiator, dependent: :destroy
  accepts_nested_attributes_for :puppeteer_recording

  scope :completed, -> { where.not(passed: nil) }
  scope :pending, -> { where(passed: nil) }
  
  scope :passed, -> { where(passed: true) }
  scope :failed, -> { where(passed: false) }

  scope :retries, -> { where.not(test_run_id_retried_from: nil) }
  scope :not_retries, -> { where(test_run_id_retried_from: nil) }

  def executed_lambda_function
    ExecutedLambdaFunction.find_by(parent_type: 'TestRun', parent_id: id)
  end

  def status
    pending? ? 'running' :
      passed? ? 'passed' : 'failed'
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

  # currently causes infinite loop
  # def original_test_run_retried_from(test_run_to_check = self)
  #   return test_run_to_check unless is_retry?
  #   original_test_run_retried_from(test_run_retried_from)
  # end

  def passed!
    update!(passed: true)
    after_passed if respond_to?(:after_passed)
  end

  def failed!(failure_message)
    update!(passed: false, results: failure_message)
    after_failed if respond_to?(:after_failed)
  end
end
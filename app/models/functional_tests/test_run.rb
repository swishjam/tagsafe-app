class TestRun < ApplicationRecord
  belongs_to :functional_test

  scope :completed, -> { where.not(passed: nil) }
  scope :pending, -> { where(passed: nil) }
  scope :passed, -> { where(passed: true) }
  scope :failed, -> { where(passed: false) }

  def status
    pending? ? 'running' :
      passed? ? 'passed' : 'failed'
  end

  # TODO: should we use timestamps..?
  def completed?
    !pending?
  end

  # TODO: should we use timestamps..?
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

  def passed!(results)
    update!(passed: true, results: results)
    after_passed if respond_to?(:after_passed)
  end

  def failed!(results)
    update!(passed: false, results: results)
    after_failed if respond_to?(:after_failed)
  end
end
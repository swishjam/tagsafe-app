class TestRun < ApplicationRecord
  belongs_to :functional_test

  scope :completed, -> { where.not(completed_at: nil) }
  scope :pending, -> { where(completed_at: nil) }
  scope :passed, -> { where(passed: true) }
  scope :failed, -> { where(passed: false) }

  def status
    pending? ? 'running' :
      passed? ? 'passed' : 'failed'
  end

  def completed?
    !pending?
  end

  def pending?
    completed_at.nil?
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
class TestRun < ApplicationRecord
  belongs_to :functional_test
  has_many :screenshots, class_name: 'TestRunScreenshot', dependent: :destroy
  accepts_nested_attributes_for :screenshots

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

  def passed!(results, logs: nil, screenshots: [])
    update!(passed: true, results: results, logs: logs, screenshots_attributes: screenshots)
    after_passed if respond_to?(:after_passed)
  end

  def failed!(results, logs: nil, screenshots: [])
    update!(passed: false, results: results, logs: logs, screenshots_attributes: screenshots)
    after_failed if respond_to?(:after_failed)
  end
end
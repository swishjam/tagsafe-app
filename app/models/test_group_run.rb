class TestGroupRun < ApplicationRecord
  belongs_to :script_change
  belongs_to :test_subscriber
  belongs_to :execution_reason
  has_many :test_runs

  scope :pending_completion, -> { where(completed_at: nil) }
  scope :by_domain, -> (domain) { where(test_subscriber: TestSubscriber.where(script_subscriber: ScriptSubscriber.where(domain: domain))) }
  # scope :by_domain, -> (domain) { joins(test_subscriber: [:script_subscriber]).where(test_subscriber: { script_subscriber: { domain: domain }}) }
  scope :failed, -> { where(passed: false) }
  scope :passed, -> { where(passed: true) }
  scope :script_change_runs, -> { where(execution_reason: ExecutionReason.SCRIPT_CHANGE) }
  scope :manual_runs, -> { where(execution_reason: [ExecutionReason.TEST, ExecutionReason.MANUAL]) }

  def completed!
    touch(:completed_at)
  end

  def result_status
    passed ? 'passed' : 'failed'
  end

  def test
    @test ||= test_subscriber.test
  end

  def script
    @script ||= test_subscriber.script
  end
end
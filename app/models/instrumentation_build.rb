class InstrumentationBuild < ApplicationRecord
  uid_prefix 'build'
  belongs_to :container

  before_create { self.enqueued_at = Time.current }
  after_create_commit { PublishInstrumentationJob.perform_later(self) }

  scope :pending_completion, -> { where(completed_at: nil) }
  scope :completed, -> { where.not(completed_at: nil) }

  def pending?
    completed_at.nil?
  end

  def completed?
    !pending?
  end

  def completed!
    raise "InstrumentationBuild is already completed." if completed?
    touch(:completed_at)
  end
end
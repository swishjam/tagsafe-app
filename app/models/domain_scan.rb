class DomainScan < ApplicationRecord
  belongs_to :domain

  scope :pending, -> { where(scan_completed_at: nil) }
  scope :completed, -> { where.not(scan_completed_at: nil) }
  scope :failed, -> { where.not(error_message: nil) }
  scope :successful, -> { completed.where(error_message: nil ) }

  def pending?
    scan_completed_at.nill?
  end

  def completed?
    !pending?
  end

  def failed?
    !error_message.nil?
  end

  def successful?
    !failed? && completed?
  end

  def completed!
    touch(:scan_completed_at)
  end

  def errored!(error_msg)
    update(error_message: error_msg)
  end
end
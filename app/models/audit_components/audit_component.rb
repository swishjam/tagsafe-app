class AuditComponent < ApplicationRecord
  include HasExecutedStepFunction
  belongs_to :audit

  serialize :raw_results, JSON
  
  before_create { self.started_at = Time.current }
  after_create_commit :perform_audit!

  scope :completed, -> { where.not(completed_at: nil) }
  scope :successful, -> { completed.where(error_message: nil) }
  scope :failed, -> { where.not(error_message: nil) }
  scope :pending, -> { where(completed_at: nil) }

  def perform_audit!
    raise "Subclass (#{self.class.to_s}) must implement `.perform_audit!` method."
  end

  def completed!(score:, raw_results:)
    update!(score: score, raw_results: raw_results, completed_at: Time.current)
    audit.after_audit_component_completed(self)
  end

  def failed!(err_msg)
    update!(error_message: err_msg)
    audit.after_audit_component_failed(self)
  end

  def weighted_score_for_audit
    score_weight * score
  end
end
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

  class << self
    attr_accessor :friendly_name
  end

  def perform_audit!
    raise "Subclass (#{self.class.to_s}) must implement `.perform_audit!` method."
  end

  def friendly_name
    self.class.friendly_name
  end

  def completed!(score:, raw_results:)
    update!(score: score, raw_results: raw_results, completed_at: Time.current)
    audit.after_audit_component_completed(self)
  end

  def failed!(err_msg)
    update!(error_message: err_msg)
    audit.after_audit_component_failed(self)
  end

  def completed?
    completed_at.present?
  end

  def successful?
    completed? && !failed?
  end

  def failed?
    error_message.present?
  end

  def pending?
    completed_at.nil?
  end

  def weighted_score_for_audit
    score_weight * score
  end

  def formatted_score
    score.round(2)
  end

  def audit_component_to_compare_with
    return unless audit.audit_to_compare_with.present?
    audit.audit_to_compare_with.audit_components.find_by(type: type)
  end

  def formatted_score
    score.round(2)
  end
end
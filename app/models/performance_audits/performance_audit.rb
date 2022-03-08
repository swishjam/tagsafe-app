class PerformanceAudit < ApplicationRecord
  include Streamable
  include HasExecutedLambdaFunction
  acts_as_paranoid
  
  belongs_to :audit, optional: false
  has_one :puppeteer_recording, as: :initiator, dependent: :destroy
  has_one :performance_audit_log, class_name: 'PerformanceAuditLog', dependent: :destroy
  has_many :blocked_resources, dependent: :destroy
  has_many :page_load_resources, foreign_key: :performance_audit_id, dependent: :destroy
  accepts_nested_attributes_for :puppeteer_recording
  accepts_nested_attributes_for :performance_audit_log
  accepts_nested_attributes_for :blocked_resources
  accepts_nested_attributes_for :page_load_resources

  scope :most_recent, -> { joins(audit: :tag_version).where(tag_versions: { most_recent: true })}
  scope :primary_audits, -> { joins(:audit).where(audits: { primary: true }) }

  scope :with_tag, -> { where(type: [IndividualPerformanceAuditWithTag.to_s, MedianIndividualPerformanceAuditWithTag.to_s, AveragePerformanceAuditWithTag.to_s]) }
  scope :without_tag, -> { where(type: [IndividualPerformanceAuditWithoutTag.to_s, MedianIndividualPerformanceAuditWithoutTag.to_s, AveragePerformanceAuditWithoutTag.to_s]) }
  scope :pending, -> { where(completed_at: nil) }
  scope :completed, -> { where.not(completed_at: nil) }
  scope :failed, -> { completed.where.not(error_message: nil) }
  scope :completed_successfully, -> { completed.where(error_message: nil) }

  def self.TYPES
    %w[
      AveragePerformanceAuditWithoutTag
      AveragePerformanceAuditWithTag
      IndividualPerformanceAuditWithoutTag
      IndividualPerformanceAuditWithTag
      MedianIndividualPerformanceAuditWithoutTag
      MedianIndividualPerformanceAuditWithTag
    ]
  end

  def self.CONFIDENCE_RANGE_COMPLETION_INDICATOR_TYPE
    'tagsafe_score_confidence_range'
  end

  def self.NUM_ITERATIONS_COMPLETION_INDICATOR_TYPE
    'num_iterations'
  end
  
  def completed!
    touch(:completed_at)
    update_column(:seconds_to_complete, completed_at - created_at)
    update_performance_audit_completion_indicator(audit: audit, now: true)
  end

  def error!(msg)
    update!(error_message: msg)
    completed!
  end

  def symbolized_audit_type
    audited_with_tag? ? :with_tag : :without_tag
  end
  
  def completed?
    !completed_at.nil?
  end

  def pending?
    !completed?
  end

  def failed?
    !error_message.nil?
  end

  def success?
    completed? && !failed?
  end
  alias successful? success?
end
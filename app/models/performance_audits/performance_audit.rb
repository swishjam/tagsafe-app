class PerformanceAudit < ApplicationRecord
  include Streamable
  include HasExecutedStepFunction
  include HasCompletedAt
  include HasErrorMessage
  # acts_as_paranoid
  
  belongs_to :audit, optional: true
  belongs_to :domain_audit, optional: true
  has_one :puppeteer_recording, as: :initiator, dependent: :destroy
  has_one :performance_audit_log, class_name: 'PerformanceAuditLog', dependent: :destroy
  has_many :blocked_resources, dependent: :destroy
  has_many :page_load_resources, foreign_key: :performance_audit_id, dependent: :destroy
  has_many :performance_audit_speed_index_frames, dependent: :destroy
  has_many :long_tasks, dependent: :destroy
  accepts_nested_attributes_for :puppeteer_recording
  accepts_nested_attributes_for :performance_audit_log
  accepts_nested_attributes_for :blocked_resources
  accepts_nested_attributes_for :page_load_resources
  accepts_nested_attributes_for :performance_audit_speed_index_frames
  accepts_nested_attributes_for :long_tasks

  scope :most_recent, -> { joins(audit: :tag_version).where(tag_versions: { most_recent: true })}
  scope :primary_audits, -> { joins(:audit).where(audits: { primary: true }) }

  scope :with_tag, -> { where(type: [IndividualPerformanceAuditWithTag.to_s, MedianIndividualPerformanceAuditWithTag.to_s, AveragePerformanceAuditWithTag.to_s]) }
  scope :without_tag, -> { where(type: [IndividualPerformanceAuditWithoutTag.to_s, MedianIndividualPerformanceAuditWithoutTag.to_s, AveragePerformanceAuditWithoutTag.to_s]) }
  scope :completed_successfully, -> { completed.successful }
  scope :does_not_have_delta_audit, -> { includes(:delta_performance_audit).where(delta_performance_audit: { id: nil }) }
  scope :in_batch, -> (batch_identifier) { where(batch_identifier: batch_identifier) }

  validate :belongs_to_audit_or_domain_audit

  after_create -> { update_performance_audit_progression_indicators(audit: audit, now: true) unless is_for_domain_audit? }

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
    # touch(:completed_at)
    update!(completed_at: Time.current, seconds_to_complete: Time.current - created_at)
    unless is_for_domain_audit?
      update_performance_audit_progression_indicators(audit: audit, now: true)
    end
  end

  def error!(msg)
    update!(error_message: msg)
    completed!
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

  def is_for_domain_audit?
    domain_audit_id.present?
  end

  def calculate_bytes
    return 0 if is_for_domain_audit?
    audit.tag_version ? audit.tag_version.bytes : fetch_live_tag_and_calculate_bytes
  end

  private

  def fetch_live_tag_and_calculate_bytes
    HTTParty.get(
      audit.tag.full_url, 
      headers: { 'User-Agent': 'Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:59.0) Gecko/20100101 Firefox/59.0' }
    ).bytesize
  rescue => e
    Rails.logger.error "Unable to fetch and calculate bytes for #{audit.tag.full_url}"
  end

  def belongs_to_audit_or_domain_audit
    if domain_audit.nil? && audit.nil?
      errors.add(:base, "PerformanceAudit must belong to either a DomainAudit or Audit.")
    end
  end
end
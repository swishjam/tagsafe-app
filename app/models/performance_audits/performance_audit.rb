class PerformanceAudit < ApplicationRecord
  include Streamable
  include HasExecutedLambdaFunction
  acts_as_paranoid
  
  belongs_to :audit, optional: false
  # has_one :delta_performance_audit, -> (perf_audit) { foreign_key: :"performance_audit_#{perf_audit.symbolized_audit_type}_id" }
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
  scope :by_tag_ids, -> (tag_ids) { joins(:audit).where(audits: { tag_id: tag_ids })}
  scope :with_tags, -> (tag_ids) { includes(audit: :tag).where(audits: { tag_id: tag_ids }) }

  scope :with_tag, -> { where(audit_performed_with_tag: true) }
  scope :without_tag, -> { where(audit_performed_with_tag: false) }
  scope :pending, -> { where(completed_at: nil) }
  scope :completed, -> { where.not(completed_at: nil) }
  scope :failed, -> { completed.where.not(error_message: nil) }
  scope :completed_successfully, -> { completed.where(error_message: nil) }

  def delta_performance_audit
    if audited_with_tag?
      DeltaPerformanceAudit.find_by(perform_audit_with_tag_id: id)
    else
      DeltaPerformanceAudit.find_by(perform_audit_without_tag_id: id)
    end
  end
  
  def completed!
    touch(:completed_at)
    update_column(:seconds_to_complete, completed_at - created_at)
    update_performance_audit_completion_indicator(audit: audit, now: true)
    if is_a?(IndividualPerformanceAudit)
      audit.enqueue_next_performance_audit!(audit_performed_with_tag)
    end
  end

  def error!(msg)
    update!(error_message: msg)
    completed!
  end

  def symbolized_audit_type
    audited_with_tag? ? :with_tag : :without_tag
  end

  def audited_with_tag?
    audit_performed_with_tag
  end
  alias with_tag? audited_with_tag?

  def audited_without_tag?
    !audit_performed_with_tag
  end
  alias without_tag? audited_without_tag?

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
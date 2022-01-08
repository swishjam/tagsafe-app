class PerformanceAudit < ApplicationRecord
  acts_as_paranoid
  
  belongs_to :audit, optional: false
  has_one :puppeteer_recording, as: :initiator, dependent: :destroy
  has_many :blocked_resources, dependent: :destroy
  has_many :page_load_resources, foreign_key: :performance_audit_id, dependent: :destroy
  has_one :performance_audit_log, class_name: 'PerformanceAuditLog', dependent: :destroy
  # doesnt like the single table inheritance...
  # has_one :executed_lambda_function
  accepts_nested_attributes_for :puppeteer_recording
  accepts_nested_attributes_for :blocked_resources
  accepts_nested_attributes_for :page_load_resources
  accepts_nested_attributes_for :performance_audit_log

  scope :most_recent, -> { joins(audit: :tag_version).where(tag_versions: { most_recent: true })}
  scope :primary_audits, -> { joins(:audit).where(audits: { primary: true }) }
  scope :by_tag_ids, -> (tag_ids) { joins(:audit).where(audits: { tag_id: tag_ids })}
  scope :with_tags, -> (tag_ids) { includes(audit: :tag).where(audits: { tag_id: tag_ids }) }

  scope :pending, -> { where(completed_at: nil) }
  scope :completed, -> { where.not(completed_at: nil) }
  scope :failed, -> { completed.where.not(error_message: nil) }
  scope :completed_successfully, -> { completed.where(error_message: nil) }

  CHARTABLE_COLUMNS = [{ title: 'DOM Complete', column: :dom_complete }, { title: 'DOM Interactive', column: :dom_interactive }, { title: 'First Contentful Paint', column: :first_contentful_paint }, { title: 'DOM Content Loaded', column: :dom_content_loaded }, { title: 'Script Duration', column: :script_duration }, { title: 'Layout Duration', column: :layout_duration }, { title: 'Task Duration', column: :task_duration }, { title: 'Tagsafe Score', column: :tagsafe_score }].freeze
  
  def executed_lambda_function
    ExecutedLambdaFunction.find_by(parent_id: id, parent_type: 'PerformanceAudit')
  end

  def completed!
    touch(:completed_at)
    update_column(:seconds_to_complete, completed_at - enqueued_at)
  end

  def error!(msg)
    update!(error_message: msg)
    completed!
    # try_retry!
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

  # def try_retry!(force = false)
  #   if should_retry? || force
  #     raise AuditError::InvalidRetry, "Cannot retry a PerformanceAudit of type #{type}" unless is_a?(IndividualPerformanceAuditWithTag) || is_a?(IndividualPerformanceAuditWithoutTag)
  #     Rails.logger.info "Retrying PerformanceAudit #{id} that failed because of #{error_message}"
  #     audit_type = is_a?(IndividualPerformanceAuditWithTag) ? :with_tag :  :without_tag
  #     AuditRunnerJobs::RunIndividualPerformanceAudit.perform_later(
  #       type: audit_type,
  #       audit: audit, 
  #       tag_version: audit.tag_version
  #     )
  #   else
  #     audit.performance_audit_error!("Haulting Performance Audit retries on audit due to exceeding max retry count of #{audit.maximum_individual_performance_audit_attempts}")
  #   end
  # end

  # def should_retry?
  #   audit.individual_performance_audits.failed.count <= audit.maximum_individual_performance_audit_attempts
  # end
end
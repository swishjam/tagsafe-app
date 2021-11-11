class PerformanceAudit < ApplicationRecord
  acts_as_paranoid
  
  belongs_to :audit, optional: false
  has_many :page_load_resources, foreign_key: :performance_audit_id, dependent: :destroy
  has_many :page_load_screenshots, foreign_key: :performance_audit_id, dependent: :destroy
  has_one :page_load_trace, foreign_key: :performance_audit_id, dependent: :destroy
  has_one :performance_audit_log, class_name: 'PerformanceAuditLog', dependent: :destroy
  # doesnt like the single table inheritance...
  # has_one :executed_lambda_function
  accepts_nested_attributes_for :performance_audit_log
  accepts_nested_attributes_for :page_load_trace

  scope :most_recent, -> { joins(audit: :tag_version).where(tag_versions: { most_recent: true })}
  scope :primary_audits, -> { joins(:audit).where(audits: { primary: true }) }
  scope :by_tag_ids, -> (tag_ids) { joins(:audit).where(audits: { tag_id: tag_ids })}
  scope :with_tags, -> (tag_ids) { includes(audit: :tag).where(audits: { tag_id: tag_ids }) }

  scope :pending, -> { where(completed_at: nil) }
  scope :completed, -> { where.not(completed_at: nil) }
  scope :failed, -> { completed.where.not(error_message: nil) }
  scope :completed_successfully, -> { completed.where(error_message: nil) }

  CHARTABLE_COLUMNS = [
    {
      title: 'DOM Complete',
      column: :dom_complete
    },
    {
      title: 'DOM Interactive',
      column: :dom_interactive
    },
    {
      title: 'First Contentful Paint',
      column: :first_contentful_paint
    },
    {
      title: 'Script Duration',
      column: :script_duration
    },
    {
      title: 'Layout Duration',
      column: :layout_duration
    },
    {
      title: 'Task Duration',
      column: :task_duration
    },
    {
      title: 'TagSafe Score',
      column: :tagsafe_score
    }
  ].freeze
  
  def executed_lambda_function
    ExecutedLambdaFunction.find_by(parent_id: id, parent_type: 'PerformanceAudit')
  end

  def previous_metric_result(metric_column)
    return nil if audit.previous_primary_audit.nil?
    audit.previous_primary_audit.performance_audits.find_by(type: type).send(metric_column).round(2)
  end

  def change_in_metric(metric_column)
    return nil if audit.previous_primary_audit.nil?
    (send(metric_column) - previous_metric_result(metric_column)).round(2)
  end

  def percent_change_in_metric(metric_column)
    return nil if audit.previous_primary_audit.nil?
    ((change_in_metric(metric_column)/previous_metric_result(metric_column))*100).round(2)
  end

  def completed!
    touch(:completed_at)
    update_column(:seconds_to_complete, completed_at - enqueued_at)
  end

  def error!(msg)
    update!(error_message: msg)
    # audit.performance_audit_error!(id)
    completed!
    try_retry!
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

  def try_retry!(force = false)
    if should_retry? || force
      raise AuditError::InvalidRetry, "Cannot retry a PerformanceAudit of type #{type}" unless is_a?(IndividualPerformanceAuditWithTag) || is_a?(IndividualPerformanceAuditWithoutTag)
      Rails.logger.info "Retrying PerformanceAudit #{id} that failed because of #{error_message}"
      lambda_sender_class = is_a?(IndividualPerformanceAuditWithTag) ? LambdaModerator::Senders::PerformanceAuditerWithTag :  LambdaModerator::Senders::PerformanceAuditerWithoutTag
      RunIndividualPerformanceAuditJob.perform_later(
        audit: audit, 
        tag_version: audit.tag_version, 
        enable_tracing: executed_lambda_function.request_payload['enable_page_load_tracing'],
        include_page_load_resources: executed_lambda_function.request_payload['include_page_load_resources'],
        inline_injected_script_tags: executed_lambda_function.request_payload['inline_injected_script_tags'],
        lambda_sender_class: lambda_sender_class
      )
    else
      Rails.logger.info "Stopping PerformanceAudit retries on audit #{audit_id} due to exceeding max retry count of #{ENV['MAX_FAILED_INDIVIDUAL_PERFORMANCE_AUDITS']}"
      Resque.logger.info "Stopping PerformanceAudit retries on audit #{audit_id} due to exceeding max retry count of #{ENV['MAX_FAILED_INDIVIDUAL_PERFORMANCE_AUDITS']}"
      audit.performance_audit_error!(id)
    end
  end

  def should_retry?
    audit.individual_performance_audits.failed.count <= (ENV['MAX_FAILED_INDIVIDUAL_PERFORMANCE_AUDITS'] || 3).to_i
  end
end
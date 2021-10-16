class PerformanceAudit < ApplicationRecord
  acts_as_paranoid
  
  belongs_to :audit
  has_many :page_load_screenshots, foreign_key: :performance_audit_id, dependent: :destroy
  has_one :page_load_trace, foreign_key: :performance_audit_id, dependent: :destroy
  has_one :performance_audit_log, class_name: 'PerformanceAuditLog', dependent: :destroy
  accepts_nested_attributes_for :performance_audit_log
  accepts_nested_attributes_for :page_load_trace

  scope :most_recent, -> { joins(audit: :tag_version).where(tag_versions: { most_recent: true })}
  scope :primary_audits, -> { joins(:audit).where(audits: { primary: true }) }
  scope :by_tag_ids, -> (tag_ids) { joins(:audit).where(audits: { tag_id: tag_ids })}
  scope :with_tags, -> (tag_ids) { includes(audit: :tag).where(audits: { tag_id: tag_ids }) }

  scope :pending, -> { where(completed_at: nil) }
  scope :completed, -> { where.not(completed_at: nil) }
  scope :failed, -> { completed.where(dom_complete: -1) }
  scope :success, -> { completed.where.not(dom_complete: -1) }

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
    audit.performance_audit_error!(id)
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
end
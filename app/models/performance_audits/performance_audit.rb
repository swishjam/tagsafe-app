class PerformanceAudit < ApplicationRecord
  belongs_to :audit
  has_one :performance_audit_logs, class_name: 'PerformanceAuditLog', dependent: :destroy
  accepts_nested_attributes_for :performance_audit_logs

  scope :most_recent, -> { joins(audit: :tag_version).where(tag_versions: { most_recent: true })}
  scope :primary_audits, -> { joins(:audit).where(audits: { primary: true }) }
  scope :by_tag_ids, -> (tag_ids) { joins(:audit).where(audits: { tag_id: tag_ids })}
  scope :with_tags, -> (tag_ids) { includes(audit: :tag).where(audits: { tag_id: tag_ids }) }

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
end
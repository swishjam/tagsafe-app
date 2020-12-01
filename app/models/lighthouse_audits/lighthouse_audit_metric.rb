class LighthouseAuditMetric < ApplicationRecord
  belongs_to :lighthouse_audit
  belongs_to :lighthouse_audit_metric_type

  scope :by_key, -> (key) { joins(:lighthouse_audit_metric_type).where(lighthouse_audit_metric_types: { key: key }) }
  scope :primary_audits, -> { includes(lighthouse_audit: :audit).where(audits: { primary: true })}
  scope :by_lighthouse_audit_type, -> (lighthouse_audit_type) { joins(:lighthouse_audit).where(lighthouse_audits: { type: lighthouse_audit_type  }) }
  scope :by_execution_reason, -> (execution_reason) { joins(lighthouse_audit: :audit).where(audits: { execution_reason_id: execution_reason.id }) }
  scope :by_script_subscriber, -> (script_subscriber) {
    includes(:lighthouse_audit_metric_type)
    .joins(lighthouse_audit: :audit)
    .where(audits: { script_subscriber_id: script_subscriber.id }) 
  }

  # create unique lighthouse_audit_result_metric_type validation with scope 

  def title
    lighthouse_audit_metric_type.title
  end

  def result_unit
    lighthouse_audit_metric_type.result_unit
  end

  def key
    lighthouse_audit_metric_type.key
  end

  def ran_at_timestamp
    lighthouse_audit.enqueued_at
  end

  def displayed_result
    return "Did not change" if result.zero?
    operator = result > 0 ? '+' : nil
    "#{operator} #{result} #{result_unit}"
  end

  def display_delta_result_outcome
    display_outcome_for_score_or_result(result, result_unit)
  end

  def display_delta_score_outcome
    display_outcome_for_score_or_result(score, 'points')
  end

  def display_outcome_for_score_or_result(score_or_result, metric_name)
    enforce_audit_type(LighthouseAuditType.DELTA)
    return "did not change #{same_metric_by_other_lighthouse_audit_type(score_or_result, LighthouseAuditType.AVERAGE_CURRENT_TAG)} #{metric_name}" if score_or_result.zero?
    operator = score_or_result > 0 ? 'increased' : 'decreased'
    "#{operator} by #{score_or_result.abs} #{metric_name}"
  end

  def delta_result_percent_of_total
    enforce_audit_type(LighthouseAuditType.DELTA)
    result/same_metric_by_other_lighthouse_audit_type(:result, LighthouseAuditType.AVERAGE_CURRENT_TAG)
  end

  def delta_score_percent_of_total
    enforce_audit_type(LighthouseAuditType.DELTA)
    score/same_metric_by_other_lighthouse_audit_type(:score, LighthouseAuditType.AVERAGE_CURRENT_TAG)
  end

  def same_metric_by_other_lighthouse_audit_type(metric, audit_type)
    lighthouse_audit.lighthouse_audit_results.by_audit_type(audit_type).first.lighthouse_audit_result_metrics.by_key(key).first[metric]
  end

  private

  def enforce_audit_type(audit_type)
    raise "#{caller_locations.first.label} can only be called by lighthouse_audit_results with a type of #{type.name}." unless lighthouse_audit_result.lighthouse_audit_type === audit_type
  end
end
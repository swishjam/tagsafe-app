require 'memoist'

class LighthouseAudit < ApplicationRecord
  class InvalidPrimaryError < StandardError; end
  extend Memoist

  belongs_to :audit
  has_many :lighthouse_audit_metrics

  scope :pending_completion, -> { where(completed_at: nil) }
  scope :completed, -> { where.not(completed_at: nil) }
  scope :older_than, -> (timestamp) { where('lighthouse_audits.enqueued_at > ?', timestamp).order(enqueued_at: :DESC) }
  scope :failed, -> { where.not(error_message: nil) }
  scope :successful, -> { where(error_message: nil) }
  scope :by_execution_reason, -> (execution_reason) { where(execution_reason: execution_reason) }

  # validate :only_one_primary

  def domain
    @domain ||= script_subscriber.domain
  end

  def script
    @script ||= script_subscriber.script
  end

  def enqueued_at
    audit.lighthouse_audit_enqueued_at
  end

  def formatted_performance_score
    (performance_score*100).round(2)
  end

  def completed!(make_primary = true)
    touch(:completed_at)
    make_primary! if make_primary
  end

  def complete?
    !completed_at.nil?
  end

  def pending?
    completed_at.nil?
  end

  def errored!(msg)
    update(error_message: msg)
  end

  def errored?
    error_message.present?
  end
  alias failed? errored?

  def is_primary?
    primary
  end
  alias primary? is_primary?

  def make_primary!
    return if is_primary?
    raise InvalidPrimaryError, "Cannot make a failed or pending lighthouse audit primary" if failed? || pending?
    script_subscriber.primary_lighthouse_audit_by_script_change(script_change)&.update_column :primary, false # bypass only_one_primary validation
    update!(primary: true)
  end

  def rgb_value_of_psi_severity
    red = green = blue = 255
    # if exceeded_psi_threshold?
    #   blue = green = psi_percent_over_threshold > 1.0 ? 75 : 255-(255*psi_percent_over_threshold)
    # end
    {
      red: red,
      green: green,
      blue: blue
    }
  end

  def previous_lighthouse_audit
    # leveraging lighthouse_audits has_many scope to enforce order
    script_subscriber.lighthouse_audits.older_than(enqueued_at).limit(1).first
  end
  memoize :previous_lighthouse_audit

  def previous_succesful_lighthouse_audit(execution_reason_or_reasons = ExecutionReason.SCRIPT_CHANGE)
    script_subscriber.lighthouse_audits.older_than(enqueued_at).by_execution_reason(execution_reason_or_reasons).successful.limit(1).first
  end
  memoize :previous_succesful_lighthouse_audit

  def delta_result
    lighthouse_audit_results.by_audit_type(LighthouseAuditType.DELTA).first
  end
  memoize :delta_result

  def delta_performance_score_is_outside_of_threshold
    delta_result.performance_score.abs > script_subscriber.lighthouse_preferences.performance_impact_threshold
  end
  memoize :delta_performance_score_is_outside_of_threshold

  def delta_performance_score
    delta_result.formatted_performance_score
  end
  memoize :delta_performance_score

  def delta_change_in_performance_score
    return 0.0 unless previous_succesful_lighthouse_audit
    previous_successful_lighthouse_audit.delta_performance_score - delta_performance_score
  end

  def delta_performance_score_percent_change
    return 0.0 unless previous_succesful_lighthouse_audit
    (delta_performance_score - previous_succesful_lighthouse_audit.delta_performance_score)/delta_performance_score
  end

  def delta_metric(metric_key)
    delta_result.lighthouse_audit_result_metrics.by_key(metric_key).first
  end

  def delta_metric_percent_change(metric_key)
    # percent change = (current - previous)/current
    if previous_succesful_lighthouse_audit
      "#{(((delta_metric(metric_key).result - previous_succesful_lighthouse_audit.delta_metric(metric_key).result)/delta_metric(metric_key).result)*100).round(2)}%"
    else
      'First Change'
    end
  end


  ###############
  # VALIDATIONS #
  ###############
  def only_one_primary
    unless script_subscriber.lighthouse_audits.where(script_change: script_change, primary: true).count === 1
      errors.add(:base, "Can only have one primary lighthouse audit for each script change.")
    end
  end
end
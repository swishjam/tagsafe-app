require 'memoist'

class Audit < ApplicationRecord
  class InvalidRetry < StandardError; end;
  class InvalidPrimaryAudit < StandardError; end;
  extend Memoist

  belongs_to :tag_version
  belongs_to :tag
  belongs_to :execution_reason

  has_many :performance_audits, dependent: :destroy
  has_one :performance_audit_with_tag
  has_one :performance_audit_without_tag
  has_one :delta_performance_audit

  ##########
  # SCOPES #
  ##########
  scope :primary, -> { where(primary: true) }

  scope :basline, -> { where(is_basline: true) }
  scope :not_basline, -> { where(is_basline: false) }

  scope :pending_performance_audit, -> { where(seconds_to_complete_performance_audit: nil) }
  scope :completed_performance_audit, -> { where.not(seconds_to_complete_performance_audit: nil) }

  scope :failed_performance_audit, -> { where.not(performance_audit_error_message: nil) }
  scope :successful_performance_audit, -> { where(performance_audit_error_message: nil) }

  scope :throttled, -> { where(throttled: true) }
  scope :not_throttled, -> { where(throttled: false) }

  def state
    performance_audit_pending? ? 'pending' :
      performance_audit_failed? ? 'failed' : 'complete'
  end

  def completed_performance_audit!
    update(seconds_to_complete_performance_audit: Time.now - performance_audit_enqueued_at)
    check_after_completion
  end

  def performance_audit_error!(err_msg, num_attempts)
    update(performance_audit_error_message: err_msg, seconds_to_complete_performance_audit: Time.now - performance_audit_enqueued_at)
    after_performance_audit_error(num_attempts)
  end

  def check_after_completion
    if complete?
      make_primary! unless primary? || performance_audit_failed?
      AuditCompletedJob.perform_later(self) unless execution_reason == ExecutionReason.INITIAL_AUDIT
    end
  end

  def after_performance_audit_error(num_attempts)
    if tag.should_retry_audits_on_errors?(num_attempts)
      Rails.logger.info "Retrying audit for tag #{tag.id}. Will be the #{num_attempts+1} attempt."
      retry!(num_attempts) 
    else
      Rails.logger.error "Reached max number of audit retry attempts: #{num_attempts}. Stopping retries."
    end
  end

  def retry!(num_attempts, reason = ExecutionReason.RETRY)
    tag_version.run_audit!(reason, num_attempts: num_attempts)
  end

  def performance_audit_failed?
    !performance_audit_error_message.nil?
  end

  def performance_audit_pending?
    seconds_to_complete_performance_audit.nil?
  end

  def performance_audit_complete?
    !performance_audit_pending?
  end
  alias performance_audit_completed? performance_audit_complete?
  alias complete? performance_audit_complete?

  def primary?
    primary
  end
  alias is_primary? primary?

  def make_primary!
    raise InvalidPrimaryAudit if performance_audit_failed? || performance_audit_pending?
    primary_audit_from_before = tag_version.primary_audit
    primary_audit_from_before.update!(primary: false) unless primary_audit_from_before.nil?
    update!(primary: true)
  end

  def previous_primary_audit
    tag.audits.joins(:tag_version).primary.where('tag_versions.created_at < ?', tag_version.created_at).limit(1).first
  end
  memoize :previous_primary_audit

  def result_metric_percent_impact(metric_key)
    ((delta_performance_audit.send(metric_key)/performance_audit_with_tag.send(metric_key))*100).round(2)
  end
end
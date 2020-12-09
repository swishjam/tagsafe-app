require 'memoist'

class Audit < ApplicationRecord
  extend Memoist

  belongs_to :script_change
  belongs_to :script_subscriber
  belongs_to :execution_reason

  has_many :performance_audits
  has_one :performance_audit_with_tag
  has_one :performance_audit_without_tag
  has_one :delta_performance_audit

  ##########
  # SCOPES #
  ##########
  scope :primary, -> { where(primary: true) }

  scope :pending_test_suite, -> { where(test_suite_completed_at: nil) }
  scope :completed_test_suite, -> { where.not(test_suite_completed_at: nil) }

  scope :pending_performance_audit, -> { where(performance_audit_completed_at: nil) }
  scope :completed_performance_audit, -> { where.not(performance_audit_completed_at: nil) }

  scope :failed_performance_audit, -> { where.not(performance_audit_error_message: nil) }
  scope :successful_performance_audit, -> { where(performance_audit_error_message: nil) }

  scope :pending_completion, -> { where(test_suite_completed_at: nil).or(where(performance_audit_completed_at: nil)) }
  scope :completed, -> { where.not(test_suite_completed_at: nil, performance_audit_completed_at: nil) }

  def completed_performance_audit!
    make_primary! unless primary?
    touch(:performance_audit_completed_at)
    check_after_completion
  end

  def performance_audit_error!(err_msg)
    update(performance_audit_error_message: err_msg)
    touch(:performance_audit_completed_at)
  end

  def completed_test_suite!
    make_primary! unless primary?
    touch(:test_suite_completed_at)
    check_after_completion
  end

  def check_after_completion
    if complete?
      AuditCompletedJob.perform_later(self)
    end
  end

  def performance_audit_failed?
    !performance_audit_error_message.nil?
  end

  def performance_audit_pending?
    performance_audit_completed_at.nil?
  end

  def performance_audit_complete?
    !performance_audit_pending?
  end
  alias performance_audit_completed? performance_audit_complete?

  def test_suite_pending?
    test_suite_completed_at.nil?
  end

  def test_suite_complete?
    !test_suite_pending?
  end
  alias test_suite_completed? test_suite_complete?

  def complete?
    performance_audit_complete? && test_suite_complete?
  end
  alias completed? complete?

  def primary?
    primary
  end
  alias is_primary? primary?

  def make_primary!
    if previous_primary_audit = script_subscriber.primary_audit_by_script_change(script_change)
      previous_primary_audit.update!(primary: false)
    end
    update!(primary: true)
  end

  def previous_primary_audit
    # leveraging audits has_many scope to enforce order
    script_subscriber.audits.primary.older_than(enqueued_at).limit(1).first
  end
  memoize :previous_primary_audit

  def result_metric_percent_impact(metric_key)
    ((delta_performance_audit.metric_result(metric_key)/performance_audit_with_tag.metric_result(metric_key))*100).round(2)
  end
end
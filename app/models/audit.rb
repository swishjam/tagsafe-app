require 'memoist'

class Audit < ApplicationRecord
  extend Memoist

  belongs_to :script_change
  belongs_to :script_subscriber
  belongs_to :execution_reason

  has_many :lighthouse_audits, dependent: :destroy

  has_one :delta_lighthouse_audit, dependent: :destroy
  has_one :average_current_tag_lighthouse_audit, dependent: :destroy
  has_one :average_without_tag_lighthouse_audit, dependent: :destroy
  has_many :current_tag_lighthouse_audits, dependent: :destroy
  has_many :without_tag_lighthouse_audits, dependent: :destroy

  ##########
  # SCOPES #
  ##########
  scope :older_than, -> (timestamp) { where('created_at > ?', timestamp) }
  scope :primary, -> { where(primary: true) }

  scope :pending_lighthouse_audits, -> { where(lighthouse_audit_completed_at: nil) }
  scope :completed_lighthouse_audits, -> { where.not(lighthouse_audit_completed_at: nil) }

  scope :failed_lighthouse_audits, -> { where.not(lighthouse_error_message: nil) }
  scope :successful_lighthouse_audits, -> { where(lighthouse_error_message: nil) }

  scope :pending_test_suite, -> { where(test_suite_completed_at: nil) }
  scope :completed_test_suites, -> { where.not(test_suite_completed_at: nil) }

  scope :pending_completion, -> { where(test_suite_completed_at: nil).or(where(lighthouse_audit_completed_at: nil)) }
  scope :completed, -> { where.not(test_suite_completed_at: nil, lighthouse_audit_completed_at: nil) }

  def completed_lighthouse_audits!
    make_primary! unless primary?
    touch(:lighthouse_audit_completed_at)
    check_after_completion
  end

  def lighthouse_audit_pending?
    lighthouse_audit_completed_at.nil?
  end

  def completed_test_suite!
    make_primary! unless primary?
    touch(:test_suite_completed_at)
    check_after_completion
  end

  def after_completion
    if complete?
      AuditCompletedJob.perform_later(self)
    end
  end

  def test_suite_pending?
    test_suite_completed_at.nil?
  end

  def pending?
    lighthouse_audit_pending? || test_suite_pending?
  end
  alias is_pending? pending?

  def lighthouse_error!(error_msg)
    update(lighthouse_error_message: error_msg)
  end

  def lighthouse_audit_failed?
    !lighthouse_error_message.nil?
  end
  alias has_failed_lighthouse_audit? lighthouse_audit_failed?

  def primary?
    primary
  end
  alias is_primary? primary?

  def complete?
    !lighthouse_audit_completed_at.nil? && !test_suite_completed_at.nil?
  end
  alias completed? complete?

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

  def exceeded_psi_threshold?
    script_subscriber.lighthouse_preferences.performance_impact_threshold.abs < delta_lighthouse_audit.performance_score.abs
  end

  def psi_over_threshold
    delta_lighthouse_audit.performance_score.abs - script_subscriber.lighthouse_preferences.performance_impact_threshold.abs
  end

  def psi_percent_over_threshold
    return 0.0 unless exceeded_psi_threshold?
    psi_over_threshold / script_subscriber.lighthouse_preferences.performance_impact_threshold.abs
  end
end
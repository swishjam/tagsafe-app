class ScriptSubscriber < ApplicationRecord
  include Rails.application.routes.url_helpers
  # has_many :test_subscriptions, class_name: 'TestSubscriber', dependent: :destroy

  # RELATIONS
  has_many :audits, -> { order('created_at DESC') }, dependent: :destroy
  belongs_to :domain
  belongs_to :script
  belongs_to :first_script_change, class_name: 'ScriptChange'
  has_many :allowed_performance_audit_tags, class_name: 'ScriptSubscriberAllowedPerformanceAuditTag', foreign_key: :performance_audit_script_subscriber_id
  has_many :script_subscriber_lint_results
  has_many :lint_results, through: :script_subscriber_lint_results

  has_many :slack_notification_subscribers, dependent: :destroy
  has_many :new_tag_slack_notifications
  has_many :script_changed_slack_notifications
  has_many :audit_completed_slack_notifications

  has_many :notification_subscribers, dependent: :destroy
  has_many :script_change_notification_subscribers, class_name: 'ScriptChangeNotificationSubscriber'
  has_many :test_failed_notification_subscribers, class_name: 'TestFailedNotificationSubscriber'
  has_many :audit_complete_notification_subscribers, class_name: 'AuditCompleteNotificationSubscriber'

  has_one :performance_audit_preferences, class_name: 'PerformanceAuditPreference'

  has_one_attached :image

  # VALIDATIONS
  validates_uniqueness_of :script_id, scope: :domain_id
  validate :within_maximum_active_script_subscriptions

  # CALLBACKS
  after_create :add_defaults
  after_update :after_update

  # SCOPES
  scope :monitor_changes, -> { where(monitor_changes: true) }
  scope :do_not_monitor_changes, -> { where(monitor_changes: false) }
  
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  
  scope :still_on_site, -> { where(removed_from_site_at: nil) }
  scope :no_longer_on_site, -> { where.not(removed_from_site_at: nil) }
  
  scope :is_third_party_tag, -> { where(is_third_party_tag: true) }
  scope :is_not_third_party_tag, -> { where(is_third_party_tag: false) }

  scope :allowed_third_party_tag, -> { where(allowed_third_party_tag: true) }
  scope :not_allowed_third_party_tag, -> { where(allowed_third_party_tag: false) }

  scope :third_party_tags_that_shouldnt_be_blocked, -> { is_third_party_tag.allowed_third_party_tag }

  def add_defaults
    create_performance_audit_preferences
    add_default_tests
  end

  def run_baseline_audit!
    run_audit!(first_script_change, ExecutionReason.INITIAL_AUDIT)
  end

  def after_update
    # if became active
    if saved_changes['active'] && saved_changes['active'][0] == false && saved_changes['active'][1] == true
      AfterScriptSubscriberActivationJob.perform_later(self)
    end
  end

  def script_changes
    script.script_changes.newer_than_or_equal_to(first_script_change.created_at).most_recent_first
  end

  def active?
    active
  end

  def inactive?
    !active
  end

  def removed_from_site?
    !removed_from_site_at.nil?
  end

  def still_on_site?
    !removed_from_site?
  end

  def try_friendly_name
    friendly_name || script.friendly_name
  end

  def try_image_url
    image.attached? ? rails_blob_url(image, host: ENV['CURRENT_HOST']) : script.try_image_url
    # image.attached? ? rails_blob_path(image, only_path: only_path) : script.try_image_url
  end

  ############
  ## AUDITS ##
  ############

  def allow_tag_on_performance_audits!(script_subscriber)
    allowed_performance_audit_tags.create(allowed_script_subscriber: script_subscriber)
  end

  def performance_audit_allowed_third_party_tag_urls
    allowed_performance_audit_tags.collect{ |ss| ss.allowed_script_subscriber.script.url }
  end

  def should_retry_audits_on_errors?(num_attempts)
    ENV['MAX_NUM_AUDIT_RETRIES'] && num_attempts < ENV['MAX_NUM_AUDIT_RETRIES'].to_i
  end

  def create_performance_audit_preferences
    PerformanceAuditPreference.create_default(self)
  end

  def run_audit_for_script_change(script_change, execution_reason = ExecutionReason.MANUAL)
    RunAuditForScriptSubscriberJob.perform_later(self, script_change, execution_reason)
  end

  def has_pending_audits_by_script_change?(script_change)
    audits.pending_completion.where(script_change: script_change).any?
  end

  def has_pending_performance_audits_by_script_change?(script_change)
  end

  def most_recent_audit_is_pending?
    most_recent_audit.pending?
  end

  def audits_by_script_change(script_change)
    # scopes = determine_audit_scopes(include_pending_lighthouse_audits: include_pending_lighthouse_audits, include_pending_test_suites: include_pending_test_suites, include_failed_lighthouse_audits: include_failed_lighthouse_audits)
    audits.where(script_change: script_change).order('audits.created_at DESC')
  end

  def most_recent_audit
    # scopes = determine_audit_scopes(include_pending_lighthouse_audits: include_pending_lighthouse_audits, include_pending_test_suites: include_pending_test_suites, include_failed_lighthouse_audits: include_failed_lighthouse_audits)
    audits.limit(1).first
  end

  def primary_audit_by_script_change(script_change)
    audits.where(script_change: script_change, primary: true).limit(1).first
  end

  def most_recent_audit_by_script_change(script_change, include_pending_performance_audits: false, include_failed_performance_audits: false)
    scopes = determine_audit_scopes(include_pending_performance_audits: include_pending_performance_audits, include_failed_performance_audits: include_failed_performance_audits)
    audits.chain_scopes(scopes).where(script_change: script_change).limit(1).first
  end

  def run_audit!(script_change, execution_reason, existing_audit: nil, num_attempts: 0)
    AuditRunner.new(
      script_subscriber: self, 
      script_change: script_change, 
      execution_reason: execution_reason,
      existing_audit: existing_audit,
      num_attempts: num_attempts
    ).run!
  end

  ###########
  ## LINTS ##
  ###########

  def lint_results_for_script_change(script_change)
    lint_results.by_script_change(script_change)
  end

  def has_lint_results_for_script_change?(script_change)
    lint_results_for_script_change(script_change).any?
  end

  ###########
  ## TESTS ##
  ###########

  def add_default_tests
    Test.default_tests.each{ |test| subscribe_to_test(test, test.default_expected_test_result) }
  end

  def subscribe_to_test(test, expected_test_result)
    test_subscriptions.create(test: test, expected_test_result: expected_test_result, active: true)
  end

  def removed_from_site!
    touch(:removed_from_site_at)
    update(active: false)
  end

  def toggle_monitor_changes_flag!
    toggle_boolean_column(:monitor_changes)
  end

  def toggle_active_flag!
    toggle_boolean_column(:active)
  end

  def toggle_third_party_flag!
    toggle_boolean_column(:is_third_party_tag)
  end

  private

  def determine_audit_scopes(include_pending_performance_audits:, include_failed_performance_audits:)
    [
      include_pending_performance_audits ? nil : :completed_performance_audit,
      # include_pending_test_suites ? nil : :completed_test_suite,
      include_failed_performance_audits ? nil : :successful_performance_audit
    ].compact || []
  end

  def within_maximum_active_script_subscriptions
    if (changed? && active_was === false && active === true) || (new_record? && active === true)
      if !domain.organization.maximum_active_script_subscriptions.nil? &&
         domain.organization.script_subscriptions.active.count + 1 > domain.organization.maximum_active_script_subscriptions
        errors.add(:base, "Cannot activate tag. Your plan only allows for #{domain.organization.maximum_active_script_subscriptions} active monitored tags.")
      end
    end
  end
end
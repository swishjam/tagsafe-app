class ScriptSubscriber < ApplicationRecord
  # has_many :test_subscriptions, class_name: 'TestSubscriber', dependent: :destroy

  has_many :audits, -> { order('created_at DESC') }, dependent: :destroy
  belongs_to :domain
  belongs_to :script
  has_one :lighthouse_preferences, class_name: 'LighthousePreference'

  has_many :script_change_notification_subscribers, class_name: 'ScriptChangeNotificationSubscriber'
  has_many :test_failed_notification_subscribers, class_name: 'TestFailedNotificationSubscriber'
  has_many :audit_complete_notification_subscribers, class_name: 'AuditCompleteNotificationSubscriber'
  has_many :lighthouse_audit_exceeded_threshold_notification_subscribers, class_name: 'LighthouseAuditExceededThresholdNotificationSubscriber'

  has_one_attached :image

  validates_uniqueness_of :script_id, scope: :domain_id

  after_update :after_update
  after_create :add_defaults

  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :should_run_lighthouse_audit, -> { joins(:lighthouse_preferences).where(lighthouse_preferences: { should_run_audit: true }) }
  scope :should_not_run_lighthouse_audit, -> { joins(:lighthouse_preferences).where(lighthouse_preferences: { should_run_audit: false }) }

  def add_defaults
    create_default_lighthouse_preferences
    add_default_tests
  end

  def after_update
    # if became active
    if saved_changes['active'] && saved_changes['active'][0] == false && saved_changes['active'][1] == true
      AfterScriptSubscriberActivationJob.perform_later(self)
    end
  end

  def active?
    active
  end

  def inactive?
    !active
  end

  def try_friendly_name
    friendly_name || script.friendly_name
  end

  def create_default_lighthouse_preferences
    raise 'LighthousePreference relation already exists' unless lighthouse_preferences.nil?
    LighthousePreference.create_default!(self)
  end

  def run_audit_for_script_change(script_change, execution_reason = ExecutionReason.MANUAL)
    RunAuditForScriptSubscriberJob.perform_later(self, script_change, execution_reason)
  end


  def lighthouse_audit_result_metrics
    LighthouseAuditResultMetric.by_script_subscriber(self)
  end

  def has_pending_audits_by_script_change?(script_change)
    audits.pending_completion.where(script_change: script_change).any?
  end

  def has_pending_lighthouse_audits_by_script_change?(script_change)
    audits.pending_lighthouse_audits.where(script_change: script_change).any?
  end

  def most_recent_audit_is_pending?
    audits.limit(1).first.pending?
  end

  def has_pending_lighthouse_audit?
    audits.pending_lighthouse_audits.any?
  end

  def audits_by_script_change(script_change, include_pending_lighthouse_audits: false, include_pending_test_suites: false, include_failed_lighthouse_audits: false)
    scopes = determine_audit_scopes(include_pending_lighthouse_audits: include_pending_lighthouse_audits, include_pending_test_suites: include_pending_test_suites, include_failed_lighthouse_audits: include_failed_lighthouse_audits)
    audits.send_chain(scopes)
            .includes(:lighthouse_audits)
            .where(script_change: script_change)
            .order('audits.created_at DESC')
  end

  def most_recent_audit(include_pending_lighthouse_audits: false, include_pending_test_suites: false, include_failed_lighthouse_audits: false)
    scopes = determine_audit_scopes(include_pending_lighthouse_audits: include_pending_lighthouse_audits, include_pending_test_suites: include_pending_test_suites, include_failed_lighthouse_audits: include_failed_lighthouse_audits)
    audits.send_chain(scopes).includes(:lighthouse_audits).limit(1).first
  end

  def primary_audit_by_script_change(script_change)
    # shouldn't have to determine scopes, primary is primary
    audits.where(script_change: script_change, primary: true).limit(1).first
  end

  def most_recent_audit_by_script_change(script_change, include_pending_lighthouse_audits: false, include_pending_test_suites: false, include_failed_lighthouse_audits: false)
    scopes = determine_audit_scopes(include_pending_lighthouse_audits: include_pending_lighthouse_audits, include_pending_test_suites: include_pending_test_suites, include_failed_lighthouse_audits: include_failed_lighthouse_audits)
    audits.send_chain(scopes).where(script_change: script_change).includes(:lighthouse_audits).limit(1).first
  end

  def run_audit!(script_change, execution_reason)
    AuditRunner.new(
      script_subscriber: self, 
      script_change: script_change, 
      execution_reason: execution_reason
    ).run!
  end

  def send_audit_complete_notifications!(audit)
    audit_complete_notification_subscribers.each{ |notification_subscriber| notification_subscriber.send_email!(audit) }
  end

  def add_default_tests
    Test.default_tests.each{ |test| subscribe_to_test(test, test.default_expected_test_result) }
  end

  def subscribe_to_test(test, expected_test_result)
    test_subscriptions.create(test: test, expected_test_result: expected_test_result, active: true)
  end

  def toggle_lighthouse_flag!
    lighthouse_preferences.update(should_run_audit: !lighthouse_preferences.should_run_audit)
  end

  def toggle_active_flag!
    update(active: !active)
  end

  private

  def determine_audit_scopes(include_pending_lighthouse_audits:, include_pending_test_suites:, include_failed_lighthouse_audits:)
    [
      include_pending_lighthouse_audits ? nil : :completed_lighthouse_audits,
      include_pending_test_suites ? nil : :completed_test_suites,
      include_failed_lighthouse_audits ? nil : :successful_lighthouse_audits
    ].compact || []
  end
end
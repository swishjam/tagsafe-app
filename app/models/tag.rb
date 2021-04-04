class Tag < ApplicationRecord
  class InvalidUnRemoval < StandardError; end;
  include Rails.application.routes.url_helpers

  # RELATIONS
  has_many :audits, -> { order('created_at DESC') }, dependent: :destroy
  belongs_to :domain
  has_many :tag_versions, -> { order('created_at DESC') }, dependent: :destroy
  has_many :tag_allowed_performance_audit_third_party_urls, dependent: :destroy
  has_many :tag_checks, -> { order('created_at DESC') }, dependent: :destroy
  
  has_many :slack_notification_subscribers, dependent: :destroy
  has_many :new_tag_slack_notifications, dependent: :destroy
  has_many :new_tag_version_slack_notifications, dependent: :destroy
  has_many :audit_completed_slack_notifications, dependent: :destroy

  has_many :email_notification_subscribers, dependent: :destroy
  has_many :new_tag_version_email_subscribers, class_name: 'NewTagVersionEmailSubscriber', dependent: :destroy
  has_many :audit_complete_notification_subscribers, class_name: 'AuditCompleteNotificationSubscriber', dependent: :destroy

  has_one :performance_audit_preferences, class_name: 'PerformanceAuditPreference', dependent: :destroy

  has_one_attached :image

  # VALIDATIONS
  validates_uniqueness_of :full_url, scope: :domain_id

  # CALLBACKS
  after_create :add_defaults
  after_update :after_update

  # SCOPES
  scope :has_completed_audits, -> { joins(:audits).where.not(audits: { id: nil, seconds_to_complete_performance_audit: nil }).where(audits: { performance_audit_error_message: nil  }) }
  scope :monitor_changes, -> { where(monitor_changes: true) }
  scope :do_not_monitor_changes, -> { where(monitor_changes: false) }
  
  scope :still_on_site, -> { where(removed_from_site_at: nil) }
  scope :removed, -> { where.not(removed_from_site_at: nil) }
  
  scope :is_third_party_tag, -> { where(is_third_party_tag: true) }
  scope :is_not_third_party_tag, -> { where(is_third_party_tag: false) }

  scope :allowed_third_party_tag, -> { where(is_allowed_third_party_tag: true) }
  scope :not_allowed_third_party_tag, -> { where(is_allowed_third_party_tag: false) }

  scope :should_run_audits, -> { where(should_run_audit: true) }
  scope :should_not_run_audits, -> { where(should_run_audit: false) }

  scope :should_log_tag_checks, -> { where(should_log_tag_checks: true) }
  scope :should_not_log_tag_checks, -> { where(should_log_tag_checks: false) }

  scope :third_party_tags_that_shouldnt_be_blocked, -> { is_third_party_tag.allowed_third_party_tag }
  scope :available_for_uptime, -> { should_log_tag_checks.is_third_party_tag.still_on_site.monitor_changes }
  scope :should_run_tag_checks, -> { monitor_changes.still_on_site.is_third_party_tag }

  scope :one_minute_interval_checks, -> { all }
  # etc...

  def self.find_without_query_params(url, include_removed_tags: false)
    parsed_url = URI.parse(url)
    if include_removed_tags
      find_by(url_domain: parsed_url.host, url_path: parsed_url.path, consider_query_param_changes_new_tag: false)
    else
      still_on_site.find_by(url_domain: parsed_url.host, url_path: parsed_url.path, consider_query_param_changes_new_tag: false)
    end
  end

  def self.find_removed_tag(url)
    removed.find_by(full_url: url)
  end

  def self.find_removed_tag_without_query_params(url)
    find_without_query_params(url, include_removed_tags: true)
  end
  
  def most_recent_version
    tag_versions.where(most_recent: true).limit(1).first
  end

  def has_no_versions?
    most_recent_version.nil?
  end

  def add_defaults
    create_performance_audit_preferences
  end

  def after_update
    # if should_run_audit became true
    if saved_changes['should_run_audit'] && saved_changes['should_run_audit'][0] == false && saved_changes['should_run_audit'][1] == true
      AfterTagShouldRunAuditActivationJob.perform_later(self)
    end
  end

  def capture_tag_content
    # make sure to return the evaluator so we can read the results afterwards
    evaluator = TagManager::Evaluator.new(self)
    evaluator.evaluate!
    evaluator
  end

  def monitor_changes?
    monitor_changes
  end
  alias monitoring_changes? monitor_changes?

  def not_monitoring_changes?
    !monitoring_changes?
  end

  def removed_from_site?
    !removed_from_site_at.nil?
  end

  def still_on_site?
    !removed_from_site?
  end

  def should_run_audit?
    should_run_audit
  end

  def should_not_run_audit?
    !should_run_audit?
  end

  def try_friendly_name
    friendly_name || full_url
  end

  def try_friendly_slug
    (friendly_name || url_domain + url_path).gsub(' ', '_').gsub('/', '_').gsub('.', '')
  end

  def try_image_url
    image.attached? ? rails_blob_url(image, host: ENV['CURRENT_HOST']) : 'https://cdn3.iconfinder.com/data/icons/online-marketing-line-3/48/109-512.png'
  end

  def domain_and_path
    domain + path
  end

  ############
  ## AUDITS ##
  ############

  def should_retry_audits_on_errors?(num_attempts)
    ENV['MAX_NUM_AUDIT_RETRIES'] && num_attempts < ENV['MAX_NUM_AUDIT_RETRIES'].to_i
  end

  def create_performance_audit_preferences
    PerformanceAuditPreference.create_default(self)
  end

  def has_pending_audits_for_tag_version?(tag_version)
    audits.pending_performance_audit.where(tag_version: tag_version).any?
  end

  def most_recent_audit(primary: true)
    if primary
      audits.where(primary: true).limit(1).first
    else
      audits.limit(1).first
    end
  end

  def most_recent_audit_by_tag_version(tag_version, include_pending_performance_audits: false, include_failed_performance_audits: false)
    scopes = determine_audit_scopes(include_pending_performance_audits: include_pending_performance_audits, include_failed_performance_audits: include_failed_performance_audits)
    audits.chain_scopes(scopes).where(tag_version: tag_version).limit(1).first
  end

  def tag_changes_per_day
    unless tag_versions.count === 1
      (tag_versions.count / ((Time.now - created_at) / 86_400)).round(2)
    end
  end

  ################
  ## TAG CHECKS ##
  ################

  def average_response_time(days_ago: 7)
    tag_checks.more_recent_than(days_ago.days.ago).average(:response_time_ms)
  end

  def max_response_time(days_ago: 7)
    tag_checks.more_recent_than(days_ago.days.ago).maximum(:response_time_ms)
  end

  def failed_requests(days_ago: 7, successful_codes: [200, 204])
    tag_checks.more_recent_than(days_ago.days.ago).where.not(response_code: successful_codes).count
  end

  def fail_rate(days_ago: 7, successful_codes: [200, 204])
    failed_requests(days_ago: days_ago, successful_codes: successful_codes) / tag_checks.more_recent_than(days_ago.days.ago).count
  end

  ###########
  # HELPERS #
  ###########

  def remove_from_site!
    touch(:removed_from_site_at)
  end

  def unremove_from_site!(send_new_tag_email = true)
    raise InvalidUnRemoval unless removed_from_site?
    unremove_from_site(send_new_tag_email)
  end

  def unremove_from_site(send_new_tag_email = true)
    update!(removed_from_site_at: nil)
    NotificationModerator::NewTagNotifier.new(self).notify! if send_new_tag_email
  end

  def toggle_monitor_changes_flag!
    toggle_boolean_column(:monitor_changes)
  end

  def toggle_third_party_flag!
    toggle_boolean_column(:is_third_party_tag)
  end

  private

  def determine_audit_scopes(include_pending_performance_audits:, include_failed_performance_audits:)
    [
      include_pending_performance_audits ? nil : :completed_performance_audit,
      include_failed_performance_audits ? nil : :successful_performance_audit
    ].compact || []
  end
end
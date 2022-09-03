class Tag < ApplicationRecord
  include Rails.application.routes.url_helpers
  include HasExecutedStepFunction
  include Notifier
  include Flaggable
  include Streamable

  uid_prefix 'tag'
  acts_as_paranoid

  attribute :execute_script_in_web_worker, default: false

  # RELATIONS
  belongs_to :most_current_audit, class_name: Audit.to_s, optional: true
  belongs_to :domain
  belongs_to :tag_identifying_data, optional: true
  belongs_to :current_live_tag_version, class_name: TagVersion.to_s, optional: true
  belongs_to :most_recent_tag_version, class_name: TagVersion.to_s, optional: true

  has_one_attached :js_script, service: :tag_js_script_s3

  has_many :audits, dependent: :destroy
  has_many :long_tasks, dependent: :destroy
  has_many :tag_versions, dependent: :destroy
  has_many :release_checks, dependent: :destroy
  has_many :uptime_checks, dependent: :destroy
  has_many :uptime_regions_to_check, class_name: UptimeRegionToCheck.to_s, dependent: :destroy
  has_many :uptime_regions, through: :uptime_regions_to_check
  has_many :urls_to_audit, class_name: UrlToAudit.to_s, dependent: :destroy
  accepts_nested_attributes_for :urls_to_audit
  has_many :functional_tests_to_run, class_name: FunctionalTestToRun.to_s, dependent: :destroy
  has_many :functional_tests, through: :functional_tests_to_run
  has_many :tag_allowed_performance_audit_third_party_urls, dependent: :destroy
  
  has_many :events, as: :triggerer, dependent: :destroy
  has_many :added_to_site_events, class_name: TagAddedToSiteEvent.to_s
  has_many :removed_from_site_events, class_name: TagRemovedFromSiteEvent.to_s
  has_many :query_param_change_events, class_name: TagUrlQueryParamsChangedEvent.to_s

  has_many :alert_configuration_tags
  has_many :alert_configurations, through: :alert_configuration_tags

  has_many :additional_tags_to_inject_during_audit, class_name: AdditionalTagToInjectDuringAudit.to_s
  has_many :tags_to_inject_during_audit, through: :additional_tags_to_inject_during_audit, source: :tag_to_inject
  # has_many :additional_tags_to_inject_self_during_audit, class_name: AdditionalTagToInjectDuringAudit.to_s, foreign_key: :tag_to_inject_id
  # has_many :tags_to_inject_self_during_audit, class_name: AdditionalTagToInjectDuringAudit.to_s, foreign_key: :tag_to_inject_id

  has_one :configuration, as: :parent, class_name: GeneralConfiguration.to_s, dependent: :destroy
  has_many :tag_configurations, dependent: :destroy
  has_one :draft_tag_configuration
  has_one :live_tag_configuration
  accepts_nested_attributes_for :tag_configurations

  # VALIDATIONS
  validates_uniqueness_of :full_url, 
                          scope: :domain_id, 
                          conditions: -> { where(deleted_at: nil) },
                          message: Proc.new{ |tag| "A tag from #{tag.full_url} already exists on #{tag.domain.url}" },
                          unless: -> { full_url.blank? }

  # CALLBACKS
  after_create :find_tag_url_in_js_script_if_necessary
  after_create :set_js_script_fingerprint
  after_create :set_url_attributes_if_necessary
  after_create :apply_tag_identifying_data_and_functional_tests

  # SCOPES
  scope :has_staged_changes, -> { where(has_staged_changes: true) }

  scope :domain_has_active_subscription_plan, -> { joins(:domain).where(Domain.has_valid_subscription) }
  scope :domain_has_invalid_subscription_plan, -> { joins(:domain).where(Domain.has_invalid_subscription) }

  scope :pending_tag_version_capture, -> { where.not(marked_as_pending_tag_version_capture_at: nil) }
  scope :not_pending_tag_version_capture, -> { where(marked_as_pending_tag_version_capture_at: nil) }

  scope :where_live_tag_configuration, -> (where_clause) { joins(:live_tag_configuration).where(live_tag_configuration: where_clause) }
  scope :where_live_tag_configuration_not, -> (where_clause) { joins(:live_tag_configuration).where.not(live_tag_configuration: where_clause) }

  scope :five_minute_scheduled_audit_intervals, -> { where_live_tag_configuration(scheduled_audit_minute_interval: 5) }
  scope :fifteen_minute_scheduled_audit_intervals, -> { where_live_tag_configuration(scheduled_audit_minute_interval: 15) }
  scope :thirty_minute_scheduled_audit_intervals, -> { where_live_tag_configuration(scheduled_audit_minute_interval: 30) }
  scope :one_hour_scheduled_audit_intervals, -> { where_live_tag_configuration(scheduled_audit_minute_interval: 60) }
  scope :three_hour_scheduled_audit_intervals, -> { where_live_tag_configuration(scheduled_audit_minute_interval: 180) }
  scope :six_hour_scheduled_audit_intervals, -> { where_live_tag_configuration(scheduled_audit_minute_interval: 360) }
  scope :twelve_hour_scheduled_audit_intervals, -> { where_live_tag_configuration(scheduled_audit_minute_interval: 720) }
  scope :twenty_four_hour_scheduled_audit_intervals, -> { where_live_tag_configuration(scheduled_audit_minute_interval: 1440) }

  def self.find_without_query_params(url, include_removed_tags: false)
    parsed_url = URI.parse(url)
    find_by(url_domain: parsed_url.host, url_path: parsed_url.path)
  end

  def self.find_removed_tag(url)
    removed.find_by(full_url: url)
  end

  def self.find_removed_tag_without_query_params(url)
    find_without_query_params(url, include_removed_tags: true)
  end

  def has_url?
    !full_url.blank?
  end

  def set_url_attributes_if_necessary
    return if self.full_url.nil?
    parsed_url = URI.parse(full_url)
    self.url_domain = parsed_url.host
    self.url_path = parsed_url.path
    self.url_query_param = parsed_url.query
    self.save!
  end

  def find_tag_url_in_js_script_if_necessary
    return unless has_js_script? && self.full_url.nil?
    temp_file_js_script_content = File.read(attachment_changes['js_script'].attachable[:io])
    tag_url = TagManager::FindTagInJsScript.find!(temp_file_js_script_content)
    return if tag_url == self.full_url
    self.full_url = tag_url
    self.save!
  end

  def set_js_script_fingerprint
    return unless has_js_script? && js_script_fingerprint.nil?
    self.js_script_fingerprint = Digest::MD5.hexdigest(js_script_content)
    self.save!
  end

  def set_current_live_tag_version(tag_version)
    update!(current_live_tag_version: tag_version)
  end

  def has_js_script?
    js_script.attached?
  end

  def js_script_content(sanitize: true)
    return nil unless js_script.attached?
    content = js_script.download
    return content unless sanitize
    # https://github.com/babel/babel/issues/9765
    content.gsub("\\", "\\\\\\\\").gsub("\n", "").gsub("\r", "")
  end

  def find_and_apply_tag_identifying_data(force_update = false)
    if full_url.present? && (tag_identifying_data_id.nil? || force_update)
      update!(tag_identifying_data: TagIdentifyingData.for_tag(self))
    end
  end

  def enabled?
    live_tag_configuration && live_tag_configuration.enabled
  end

  def disabled?
    !enabled?
  end

  def url_scheme
    URI.parse(full_url).scheme
  end

  def after_create_notification_msg
    "A new tag has been detected: #{full_url}"
  end

  def notification_image_url
    try_image_url
  end

  def able_to_be_tagsafe_hosted?
    url_query_param.blank?
  end

  def apply_tag_identifying_data_and_functional_tests
    # TagImageDomainLookupPattern.find_and_apply_image_to_tag(self)
    find_and_apply_tag_identifying_data
    # uptime_regions_to_check.create(uptime_region: UptimeRegion.US_EAST_1) # new uptime check logic no longer requires this...
    domain.functional_tests.run_on_all_tags.each{ |test| test.enable_for_tag(self) }
  end

  def state
    live_tag_configuration.nil? ? 'pending' : live_tag_configuration.disabled? ? 'disabled' : 'live'
  end

  def human_state
    state.split('-').collect(&:capitalize).join(' ')
  end

  # def most_current_audit
  #   audits.most_current.limit(1).first
  # end

  def current_sri_value
    current_version.nil? ? nil : "sha256-#{current_version.sha_256}"
  end
  
  def most_recent_version
    # tag_versions.where(most_recent: true).limit(1).first
    most_recent_tag_version
  end
  alias current_version most_recent_version

  def first_version
    tag_versions.most_recent_last.limit(1).first
  end

  def has_no_versions?
    most_recent_version.nil?
  end

  def run_uptime_check_now!
    RunReleaseCheckJob.perform_now(self)
  end

  def run_uptime_check_later!
    RunReleaseCheckJob.perform_later(self)
  end

  def perform_audit_on_all_urls_on_current_tag_version!(execution_reason:, initiated_by_domain_user: nil)
    if release_monitoring_enabled?
      perform_audit_on_all_urls!(
        execution_reason: execution_reason, 
        tag_version: current_version,
        initiated_by_domain_user: initiated_by_domain_user,
      )
    else
      perform_audit_on_all_urls!(
        execution_reason: execution_reason, 
        initiated_by_domain_user: initiated_by_domain_user,
        tag_version: nil
      )
    end
  end

  def perform_audit_on_all_urls!(execution_reason:, tag_version:, initiated_by_domain_user: nil, options: {})
    urls_to_audit.map do |url_to_audit|
      perform_audit!(
        execution_reason: execution_reason,
        tag_version: tag_version,
        initiated_by_domain_user: initiated_by_domain_user,
        url_to_audit: url_to_audit,
        options: options
      )
    end
  end

  def perform_audit!(execution_reason:, tag_version:, initiated_by_domain_user:, url_to_audit:, options: {})
    AuditHandler::Runner.new(
      execution_reason: execution_reason,
      tag: self,
      tag_version: tag_version,
      url_to_audit: url_to_audit,
      initiated_by_domain_user: initiated_by_domain_user,
      options: options
    ).run!
  end

  def release_monitoring_enabled?
    live_tag_configuration.present? && live_tag_configuration.release_monitoring_enabled?
  end

  def scheduled_audits_enabled?
    live_tag_configuration.present? && live_tag_configuration.scheduled_audits_enabled?
  end

  def tag_or_domain_configuration
    configuration || domain.general_configuration
  end

  def should_roll_up_audits_by_tag_version?
    release_monitoring_disabled? ? false : domain.general_configuration.roll_up_audits_by_tag_version
  end

  def audit_to_display(include_pending: true)
    most_recent_successful_audit || (include_pending ? most_recent_pending_audit : nil)
  end

  def most_recent_successful_audit
    audits.completed_performance_audit.successful_performance_audit.most_recent_first.limit(1).first
  end

  def most_recent_pending_audit
    audits.pending_performance_audit.most_recent_first.limit(1).first
  end

  def has_friendly_name?
    tag_identifying_data.present?
  end

  def friendly_name
    tag_identifying_data&.name
  end

  def try_friendly_name
    friendly_name || url_based_on_preferences
  end

  def url_based_on_preferences
    domain_and_path
  end

  def try_friendly_slug
    (friendly_name || url_domain + url_path).gsub(' ', '_').gsub('/', '_').gsub('.', '')
  end

  def has_image?
    tag_identifying_data&.image.present?
  end

  def try_image_url
    tag_identifying_data&.image&.url || 'https://cdn3.iconfinder.com/data/icons/online-marketing-line-3/48/109-512.png'
  end
  alias image_url try_image_url

  def domain_and_path
    return if full_url.nil?
    "#{URI.parse(full_url).scheme}://#{url_domain}#{url_path}"
  end

  def estimated_monthly_cost
    SubscriptionMaintainer::PriceEstimator.new(self).estimate_monthly_price
  end

  ################
  ## TAG CHECKS ##
  ################

  def average_response_time(days_ago: 7)
    uptime_checks.more_recent_than(days_ago.days.ago).average(:response_time_ms)&.round(2)
  end

  def max_response_time(days_ago: 7, round: true)
    uptime_checks.more_recent_than(days_ago.days.ago).maximum(:response_time_ms)
  end

  def total_num_of_requests(days_ago: 7)
    uptime_checks.more_recent_than(days_ago.days.ago).count
  end

  def num_failed_requests(days_ago: 7, successful_codes: [200, 204])
    uptime_checks.more_recent_than(days_ago.days.ago).where.not(response_code: successful_codes).count
  end

  def fail_rate(days_ago: 7, successful_codes: [200, 204])
    failed_count = num_failed_requests(days_ago: days_ago, successful_codes: successful_codes).to_f
    return 0 if failed_count.zero?
    (failed_count / total_num_of_requests(days_ago: days_ago) * 100).round(2)
  end
end
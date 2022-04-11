class Tag < ApplicationRecord
  include Rails.application.routes.url_helpers
  include HasExecutedLambdaFunction
  include Notifier
  include Flaggable
  include Streamable

  uid_prefix 'tag'
  acts_as_paranoid

  # RELATIONS
  belongs_to :domain
  belongs_to :tag_identifying_data, optional: true
  belongs_to :found_on_page_url, class_name: PageUrl.to_s
  belongs_to :found_on_url_crawl, class_name: UrlCrawl.to_s
  
  has_many :audits, dependent: :destroy  
  has_many :tag_versions, dependent: :destroy
  has_many :tag_checks, dependent: :destroy
  has_many :tag_check_regions_to_check, dependent: :destroy, class_name: TagCheckRegionToCheck.to_s
  has_many :tag_check_regions, through: :tag_check_regions_to_check
  has_many :urls_to_audit, class_name: UrlToAudit.to_s, dependent: :destroy
  has_many :functional_tests_to_run, class_name: FunctionalTestToRun.to_s, dependent: :destroy
  has_many :functional_tests, through: :functional_tests_to_run
  has_many :tag_allowed_performance_audit_third_party_urls, dependent: :destroy
  
  has_many :events, as: :triggerer, dependent: :destroy
  has_many :added_to_site_events, class_name: TagAddedToSiteEvent.to_s
  has_many :removed_from_site_events, class_name: TagRemovedFromSiteEvent.to_s
  has_many :query_param_change_events, class_name: TagUrlQueryParamsChangedEvent.to_s

  has_many :triggered_alerts

  has_one :configuration, as: :parent, class_name: GeneralConfiguration.to_s, dependent: :destroy
  has_one :tag_preferences, class_name: TagPreference.to_s, dependent: :destroy
  accepts_nested_attributes_for :tag_preferences

  # VALIDATIONS
  validates_presence_of :full_url
  validates_uniqueness_of :full_url, 
                          scope: :domain_id, 
                          conditions: -> { where(deleted_at: nil) },
                          message: Proc.new{ |tag| "A tag from #{tag.full_url} already exists on #{tag.domain.url}" }

  # CALLBACKS
  broadcast_notification on: :create
  after_update_commit { update_tag_table_row(tag: self, now: true) }
  after_destroy_commit { remove_tag_from_from_table(tag: self) }
  after_destroy { LambdaCronJobDataStore::TagCheckIntervals.remove_tag_id_from_every_tag_check_region(id) }
  after_destroy { LambdaCronJobDataStore::TagCheckConfigurations.delete_tag_check_configuration_by_tag_id(id) }
  after_create { LambdaCronJobDataStore::TagCheckConfigurations.new(self).update_tag_check_configuration }
  after_create_commit :apply_defaults
  after_create_commit :stream_new_tag_to_views
  after_create_commit { TagAddedToSiteEvent.create(triggerer: self) }
  after_create_commit { NewTagAlert.create!(initiating_record: self, tag: self) }
  after_create_commit { run_tag_check_later! if release_monitoring_enabled? }

  # SCOPES
  default_scope { includes(:tag_identifying_data, :tag_preferences) }
  
  scope :release_monitoring_enabled, -> { where_tag_preferences_not({ tag_check_minute_interval: nil }) }
  scope :release_monitoring_disabled, -> { where_tag_preferences({ tag_check_minute_interval: nil }) }

  scope :scheduled_audits_enabled, -> { where_tag_preferences_not({ scheduled_audit_minute_interval: nil }) }
  scope :scheduled_audits_disabled, -> { where_tag_preferences({ scheduled_audit_minute_interval: nil }) }
  
  scope :still_on_site, -> { where(removed_from_site_at: nil) }
  scope :removed, -> { where.not(removed_from_site_at: nil) }
  
  scope :is_third_party_tag, -> { where_tag_preferences({ is_third_party_tag: true }) }
  scope :is_not_third_party_tag, -> { where_tag_preferences({ is_third_party_tag: false }) }

  scope :allowed_third_party_tag, -> { where_tag_preferences({ is_allowed_third_party_tag: true }) }
  scope :not_allowed_third_party_tag, -> { where_tag_preferences({ is_allowed_third_party_tag: false }) }

  scope :should_log_tag_checks, -> { where_tag_preferences({ should_log_tag_checks: true }) }
  scope :should_not_log_tag_checks, -> { where_tag_preferences({ should_log_tag_checks: false }) }

  scope :should_consider_query_param_changes_new_tag, -> { where_tag_preferences({ consider_query_param_changes_new_tag: true }) }
  scope :should_not_consider_query_param_changes_new_tag, -> { where_tag_preferences({ consider_query_param_changes_new_tag: false }) }

  scope :third_party_tags_that_shouldnt_be_blocked, -> { is_third_party_tag.allowed_third_party_tag }
  scope :available_for_uptime, -> { should_log_tag_checks.is_third_party_tag.still_on_site.release_monitoring_enabled }
  scope :should_run_tag_checks, -> { enabled.still_on_site.is_third_party_tag }
  scope :chartable, -> { is_third_party_tag.still_on_site.not_allowed_third_party_tag }
  scope :has_content, -> { where(has_content: true) }
  scope :doesnt_have_content, -> { where(has_content: false) }

  scope :domain_has_active_subscription_plan, -> { includes(domain: [:subscription_plan]).where.not(domain: { subscription_plans: { status: SubscriptionPlan::DELINQUENT_STATUSES }}) }
  scope :domain_has_delinquent_subscription_plan, -> { includes(domain: [:subscription_plan]).where(domain: { subscription_plans: { status: SubscriptionPlan::DELINQUENT_STATUSES }}) }

  scope :one_minute_interval_checks, -> { where_tag_preferences(tag_check_minute_interval: 1) }
  scope :fifteen_minute_interval_checks, -> { where_tag_preferences(tag_check_minute_interval: 15) }
  scope :thirty_minute_interval_checks, -> { where_tag_preferences(tag_check_minute_interval: 30) }
  scope :one_hour_interval_checks, -> { where_tag_preferences(tag_check_minute_interval: 60) }
  scope :three_hour_interval_checks, -> { where_tag_preferences(tag_check_minute_interval: 180) }
  scope :six_hour_interval_checks, -> { where_tag_preferences(tag_check_minute_interval: 360) }
  scope :twelve_hour_interval_checks, -> { where_tag_preferences(tag_check_minute_interval: 720) }
  scope :twenty_four_hour_interval_checks, -> { where_tag_preferences(tag_check_minute_interval: 1440) }
  scope :one_day_interval_checks, -> { twenty_four_hour_interval_checks }

  scope :five_minute_scheduled_audit_intervals, -> { where_tag_preferences(scheduled_audit_minute_interval: 5) }
  scope :fifteen_minute_scheduled_audit_intervals, -> { where_tag_preferences(scheduled_audit_minute_interval: 15) }
  scope :thirty_minute_scheduled_audit_intervals, -> { where_tag_preferences(scheduled_audit_minute_interval: 30) }
  scope :one_hour_scheduled_audit_intervals, -> { where_tag_preferences(scheduled_audit_minute_interval: 60) }
  scope :three_hour_scheduled_audit_intervals, -> { where_tag_preferences(scheduled_audit_minute_interval: 180) }
  scope :six_hour_scheduled_audit_intervals, -> { where_tag_preferences(scheduled_audit_minute_interval: 360) }
  scope :twelve_hour_scheduled_audit_intervals, -> { where_tag_preferences(scheduled_audit_minute_interval: 720) }
  scope :twenty_four_hour_scheduled_audit_intervals, -> { where_tag_preferences(scheduled_audit_minute_interval: 1440) }

  def self.where_tag_preferences(where_clause)
    joins(:tag_preferences).where(tag_preferences: where_clause)
  end

  def self.where_tag_preferences_not(where_clause)
    joins(:tag_preferences).where.not(tag_preferences: where_clause)
  end

  def self.find_without_query_params(url, include_removed_tags: false)
    parsed_url = URI.parse(url)
    if include_removed_tags
      should_not_consider_query_param_changes_new_tag.find_by(url_domain: parsed_url.host, url_path: parsed_url.path)
    else
      still_on_site.should_not_consider_query_param_changes_new_tag.find_by(url_domain: parsed_url.host, url_path: parsed_url.path)
    end
  end

  def self.find_removed_tag(url)
    removed.find_by(full_url: url)
  end

  def self.find_removed_tag_without_query_params(url)
    find_without_query_params(url, include_removed_tags: true)
  end

  def find_and_apply_tag_identifying_data(force_update = false)
    unless tag_identifying_data.present? || force_update
      update!(tag_identifying_data: TagIdentifyingData.for_tag(self))
    end
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

  def apply_defaults
    # TagImageDomainLookupPattern.find_and_apply_image_to_tag(self)
    find_and_apply_tag_identifying_data
    tag_check_regions_to_check.create(tag_check_region: TagCheckRegion.US_EAST_1)
    domain.functional_tests.run_on_all_tags.each{ |test| test.enable_for_tag(self) }
  end

  def stream_new_tag_to_views
    if domain.tags.count == 1
      # render the table empty and allow `append_tag_row_to_table` to add the new tag
      re_render_tags_table(domain: domain, empty: true, now: true)
      re_render_tags_chart(domain: domain, now: true)
    end
    append_tag_row_to_table(tag: self, now: true)
  end

  def state
    removed_from_site? ? 'removed' :
      release_monitoring_enabled? ? 'active' : 'disabled'
  end

  def human_state
    state.split('-').collect(&:capitalize).join(' ')
  end
  
  def most_recent_version
    return nil if release_monitoring_disabled?
    tag_versions.where(most_recent: true).limit(1).first
  end
  alias current_version most_recent_version

  def first_version
    tag_versions.most_recent_last.limit(1).first
  end

  def has_no_versions?
    most_recent_version.nil?
  end

  def run_tag_check_now!
    RunTagCheckJob.perform_now(self)
  end

  def run_tag_check_later!
    RunTagCheckJob.perform_later(self)
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
    AuditRunner.new(
      execution_reason: execution_reason,
      tag: self,
      tag_version: tag_version,
      url_to_audit: url_to_audit,
      initiated_by_domain_user: initiated_by_domain_user,
      options: options
    ).run!
  end

  def removed_from_site?
    !removed_from_site_at.nil?
  end

  def mark_as_removed_from_site!(removed_timestamp = Time.now)
    update!(removed_from_site_at: removed_timestamp)
    RemovedTagAlert.create!(tag: self, initiating_record: self)
  end

  def release_monitoring_enabled?
    tag_preferences.release_monitoring_enabled?
  end

  def scheduled_audits_enabled?
    !tag_preferences.scheduled_audit_minute_interval.nil?
  end

  def enable!
    tag_preferences.update!(enabled: true)
  end

  def disabled?
    tag_preferences.release_monitoring_disabled?
  end
  alias release_monitoring_disabled? disabled?

  def scheduled_audits_disabled?
    !scheduled_audits_enabled?
  end

  def disable!
    tag_preferences.update!(enabled: false)
  end

  def tag_or_domain_configuration
    configuration || domain.general_configuration
  end

  def should_roll_up_audits_by_tag_version?
    release_monitoring_disabled? ? false : domain.general_configuration.roll_up_audits_by_tag_version
  end

  def audit_to_display
    if should_roll_up_audits_by_tag_version?
      current_version&.audit_to_display
    else
      most_recent_successful_audit
    end
  end

  def most_recent_successful_audit
    audits.most_recent_first.completed.successful_performance_audit.limit(1).first || audits.most_recent_first.pending_performance_audit.limit(1).first
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
    tag_preferences.consider_query_param_changes_new_tag ? full_url : domain_and_path
  end

  def try_friendly_slug
    (friendly_name || url_domain + url_path).gsub(' ', '_').gsub('/', '_').gsub('.', '')
  end

  def try_image_url
    tag_identifying_data&.image&.url || 'https://cdn3.iconfinder.com/data/icons/online-marketing-line-3/48/109-512.png'
  end
  alias image_url try_image_url

  def domain_and_path
    "#{URI.parse(full_url).scheme}://#{url_domain}#{url_path}"
  end

  def estimated_monthly_cost
    SubscriptionMaintainer::PriceEstimator.new(self).estimate_monthly_price
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

  def total_num_of_requests(days_ago: 7)
    tag_checks.more_recent_than(days_ago.days.ago).count
  end

  def num_failed_requests(days_ago: 7, successful_codes: [200, 204])
    tag_checks.more_recent_than(days_ago.days.ago).where.not(response_code: successful_codes).count
  end

  def fail_rate(days_ago: 7, successful_codes: [200, 204])
    (num_failed_requests(days_ago: days_ago, successful_codes: successful_codes).to_f / total_num_of_requests(days_ago: days_ago) * 100).round(2)
  end
end
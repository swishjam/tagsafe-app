class Tag < ApplicationRecord
  include Rails.application.routes.url_helpers
  include Notifier
  include Flaggable
  include Streamable

  uid_prefix 'tag'
  acts_as_paranoid

  # RELATIONS
  belongs_to :domain
  belongs_to :tag_identifying_data, optional: true
  belongs_to :found_on_page_url, class_name: 'PageUrl'
  belongs_to :found_on_url_crawl, class_name: 'UrlCrawl'
  
  # has_many :audits, -> { order('created_at DESC') }, dependent: :destroy  
  has_many :audits, dependent: :destroy  
  # has_many :tag_versions, -> { order('created_at DESC') }, dependent: :destroy
  has_many :tag_versions, dependent: :destroy
  has_many :tag_allowed_performance_audit_third_party_urls, dependent: :destroy
  # has_many :tag_checks, -> { order('created_at DESC') }, dependent: :destroy
  has_many :tag_checks, dependent: :destroy
  has_many :urls_to_audit, class_name: 'UrlToAudit', dependent: :destroy
  has_many :functional_tests_to_run, class_name: 'FunctionalTestToRun', dependent: :destroy
  has_many :functional_tests, through: :functional_tests_to_run
  
  has_many :events, as: :triggerer, dependent: :destroy
  has_many :added_to_site_events, class_name: 'TagAddedToSiteEvent'
  has_many :removed_from_site_events, class_name: 'TagRemovedFromSiteEvent'
  has_many :query_param_change_events, class_name: 'TagUrlQueryParamChangedEvent'
  
  has_many :slack_notification_subscribers, dependent: :destroy
  has_many :new_tag_slack_notifications, dependent: :destroy
  has_many :new_tag_version_slack_notifications, dependent: :destroy
  has_many :audit_completed_slack_notifications, dependent: :destroy

  has_many :email_notification_subscribers, dependent: :destroy
  has_many :new_tag_version_email_subscribers, class_name: 'NewTagVersionEmailSubscriber', dependent: :destroy
  has_many :audit_complete_notification_subscribers, class_name: 'AuditCompleteNotificationSubscriber', dependent: :destroy

  has_one :default_audit_configuration, as: :parent, class_name: 'DefaultAuditConfiguration', dependent: :destroy
  has_one :tag_preferences, class_name: 'TagPreference', dependent: :destroy
  accepts_nested_attributes_for :tag_preferences

  # VALIDATIONS
  validates_presence_of :full_url
  validates_uniqueness_of :full_url, scope: :domain_id, conditions: -> { where(deleted_at: nil) }

  # CALLBACKS
  broadcast_notification on: :create
  after_create_commit :stream_new_tag_to_views
  after_update_commit { update_tag_table_row(tag: self, now: true) }
  after_destroy_commit { remove_tag_from_from_table(tag: self) }
  after_create { TagAddedToSiteEvent.create(triggerer: self) }
  after_create :apply_defaults

  # SCOPES
  default_scope { includes(:tag_identifying_data) }
  
  scope :enabled, -> { where_tag_preferences({ enabled: true }) }
  scope :disabled, -> { where_tag_preferences({ enabled: false }) }
  
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
  scope :available_for_uptime, -> { should_log_tag_checks.is_third_party_tag.still_on_site.enabled }
  scope :should_run_tag_checks, -> { enabled.still_on_site.is_third_party_tag }
  scope :chartable, -> { is_third_party_tag.still_on_site.not_allowed_third_party_tag }

  scope :one_minute_interval_checks, -> { all }
  # etc...

  def self.where_tag_preferences(where_clause)
    joins(:tag_preferences).where(tag_preferences: where_clause)
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

  def find_and_apply_tag_identifying_data
    update!(tag_identifying_data: TagIdentifyingData.for_tag(self))
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
      enabled? ? 'active' : 'disabled'
  end

  def human_state
    state.split('-').collect(&:capitalize).join(' ')
  end
  
  def most_recent_version
    tag_versions.where(most_recent: true).limit(1).first
  end
  alias current_version most_recent_version

  def first_version
    tag_versions.most_recent_last.limit(1).first
  end

  def has_no_versions?
    most_recent_version.nil?
  end

  def run_tag_check!
    # make sure to return the evaluator so we can read the results afterwards
    evaluator = TagManager::Evaluator.new(self)
    evaluator.evaluate!
    evaluator
  end

  def removed_from_site?
    !removed_from_site_at.nil?
  end

  def enabled?
    tag_preferences.enabled
  end

  def enable!
    tag_preferences.update!(enabled: true)
  end

  def disabled?
    !enabled?
  end

  def disable!
    tag_preferences.update!(enabled: false)
  end

  def try_friendly_name
    # friendly_name || url_based_on_preferences
    tag_identifying_data&.name || url_based_on_preferences
  end

  def url_based_on_preferences
    tag_preferences.consider_query_param_changes_new_tag ? full_url : domain_and_path
  end

  def try_friendly_slug
    (friendly_name || url_domain + url_path).gsub(' ', '_').gsub('/', '_').gsub('.', '')
  end

  def try_image_url
    tag_identifying_data&.image&.attached? ? rails_blob_url(tag_identifying_data.image, host: ENV['CURRENT_HOST']) : 'https://cdn3.iconfinder.com/data/icons/online-marketing-line-3/48/109-512.png'
  end
  alias image_url try_image_url

  def domain_and_path
    "#{URI.parse(full_url).scheme}://#{url_domain}#{url_path}"
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
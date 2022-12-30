class Tag < ApplicationRecord
  include Rails.application.routes.url_helpers
  include HasExecutedStepFunction
  include Notifier
  include Streamable

  uid_prefix 'tag'
  acts_as_paranoid

  attribute :release_monitoring_interval_in_minutes, default: 180
  attribute :tagsafe_js_intercepted_count, default: 0
  attribute :tagsafe_js_not_intercepted_count, default: 0
  attribute :tagsafe_js_optimized_count, default: 0

  # RELATIONS
  belongs_to :container
  belongs_to :primary_audit, class_name: Audit.to_s, optional: true
  belongs_to :tag_identifying_data, optional: true
  belongs_to :tagsafe_js_event_batch, optional: true
  belongs_to :page_load_found_on, class_name: PageLoad.to_s, optional: true # optional for legacy Tags
  belongs_to :current_live_tag_version, class_name: TagVersion.to_s, optional: true
  belongs_to :most_recent_tag_version, class_name: TagVersion.to_s, optional: true

  has_many :audits, dependent: :destroy
  has_many :tag_versions, dependent: :destroy
  has_many :release_checks, dependent: :destroy
  has_many :uptime_checks, dependent: :destroy
  has_many :uptime_regions_to_check, class_name: UptimeRegionToCheck.to_s, dependent: :destroy
  has_many :uptime_regions, through: :uptime_regions_to_check
  has_many :page_urls_tag_found_on, class_name: PageUrlTagFoundOn.to_s, dependent: :destroy
  has_many :page_urls, through: :page_urls_tag_found_on
  has_many :functional_tests_to_run, class_name: FunctionalTestToRun.to_s, dependent: :destroy
  has_many :functional_tests, through: :functional_tests_to_run
  has_many :alert_configuration_tags, dependent: :destroy
  has_many :alert_configurations, through: :alert_configuration_tags

  accepts_nested_attributes_for :page_urls_tag_found_on

  SUPPORTED_RELEASE_MONITORING_INTERVALS = [0, 1, 15, 30, 60, 180, 360, 720, 1_440]
  
  # VALIDATIONS
  validate :has_at_least_one_page_url_tag_found_on
  validates :release_monitoring_interval_in_minutes, inclusion: { in: SUPPORTED_RELEASE_MONITORING_INTERVALS }
  validates :load_type, inclusion: { in: ['async', 'defer', 'synchronous'] }
  validates :page_load_found_on, presence: true, on: :create # only on create to support legacy Tags
  validates_uniqueness_of :full_url, 
                          scope: :container_id, 
                          conditions: -> { where(deleted_at: nil) },
                          message: Proc.new{ |tag| "A tag from #{tag.full_url} already exists on this Container (#{tag.container.name} - #{tag.container.uid})" }

  # CALLBACKS
  before_create :set_parsed_url_attributes
  before_create { self.tag_identifying_data = TagIdentifyingData.for_tag(self) }
  before_create { self.last_seen_at = Time.current }
  # TODO: should we capture the first TagVersion for _all_ tags?
  after_create { TagManager::MarkTagAsTagsafeHostedIfPossible.new(self).determine! }
  after_create { TagManager::TagVersionFetcher.new(self).fetch_and_capture_first_tag_version! if is_tagsafe_hostable }
  after_create { perform_audit_on_all_should_audit_urls!(execution_reason: ExecutionReason.NEW_RELEASE, tag_version: nil, initiated_by_container_user: nil) if !is_tagsafe_hostable }
  after_create :enable_aws_event_bridge_rules_for_release_check_interval_if_necessary!
  after_create_commit :broadcast_new_tag_notification_to_all_users
  after_update :check_to_sync_aws_event_bridge_rules_if_necessary

  # SCOPES
  scope :pending_tag_version_capture, -> { where.not(marked_as_pending_tag_version_capture_at: nil) }
  scope :not_pending_tag_version_capture, -> { where(marked_as_pending_tag_version_capture_at: nil) }
  scope :tagsafe_hosted, -> { where(is_tagsafe_hosted: true).where.not(current_live_tag_version: nil) }
  scope :not_tagsafe_hosted, -> { where(is_tagsafe_hosted: false) }
  scope :tagsafe_hostable, -> { where(is_tagsafe_hostable: true) }
  scope :not_tagsafe_hostable, -> { where(is_tagsafe_hostable: false) }

  def set_parsed_url_attributes
    parsed_url = URI.parse(self.full_url)
    self.url_hostname = parsed_url.host
    self.url_path = parsed_url.path
    self.url_query_param = parsed_url.query

    parsed_url.scheme = 'https' if parsed_url.scheme.nil?
    self.full_url = parsed_url.to_s
  end

  def set_current_live_tag_version_and_publish_instrumentation(tag_version)
    update!(current_live_tag_version: tag_version, primary_audit: tag_version.primary_audit)
    container.publish_instrumentation!
  end

  def find_and_apply_tag_identifying_data(force_update = false)
    if full_url.present? && (!has_tag_identifying_data? || force_update)
      update!(tag_identifying_data: TagIdentifyingData.for_tag(self))
    end
  end

  def has_tag_identifying_data?
    tag_identifying_data_id.present?
  end

  def has_most_recent_tag_version?
    most_recent_tag_version_id.present?
  end

  def has_current_live_tag_version?
    current_live_tag_version_id.present?
  end

  def release_monitoring_interval_in_words
    Util.integer_to_interval_in_words(release_monitoring_interval_in_minutes)
  end

  def enabled?
    true
  end

  def disabled?
    !enabled?
  end

  def url_scheme
    URI.parse(full_url).scheme
  end

  def notification_image_url
    try_image_url
  end

  def first_version
    tag_versions.most_recent_last.limit(1).first
  end

  def has_no_versions?
    most_recent_tag_version.nil?
  end

  def most_current_audit
    # TODO: make this more intelligent
    most_recent_successful_audit
  end

  def page_url_first_found_on
    page_urls_tag_found_on.includes(:page_url).most_recent_first.limit(1).first.page_url
  end

  def load_type_as_verb
    return load_type if %w[async defer].include?(load_type)
    "#{load_type}ly"
  end

  def perform_audit!(execution_reason:, tag_version:, initiated_by_container_user:, page_url:)
    Audit.run!(
      tag: self,
      tag_version: tag_version,
      page_url: page_url,
      initiated_by_container_user: initiated_by_container_user,
      execution_reason: execution_reason
    )
  end

  def perform_audit_on_all_should_audit_urls!(execution_reason:, tag_version:, initiated_by_container_user:)
    page_urls_tag_found_on.should_audit.includes(:page_url).each do |page_url_tag_found_on|
      perform_audit!(
        execution_reason: execution_reason, 
        tag_version: tag_version,
        page_url: page_url_tag_found_on.page_url,
        initiated_by_container_user: initiated_by_container_user
      )
    end
  end

  def release_monitoring_enabled?
    release_monitoring_interval_in_minutes > 0
  end

  def most_recent_release_check
    release_checks.most_recent_first.limit(1).first
  end

  def release_monitoring_disabled?
    !release_monitoring_enabled?
  end

  def scheduled_audits_enabled?
    false
  end

  def scheduled_audits_disabled?
    !scheduled_audits_enabled?
  end

  def tag_or_container_configuration
    # configuration || container.general_configuration
    container.general_configuration
  end

  def audit_to_display(include_pending: true)
    most_recent_successful_audit || (include_pending ? most_recent_pending_audit : nil)
  end

  def most_recent_successful_audit
    audits.successful.most_recent_first.limit(1).first
  end

  def most_recent_pending_audit
    audits.pending.most_recent_first.limit(1).first
  end

  def name
    # TODO: need to add to tags table
  end

  def has_friendly_name?
    name.present? || tag_identifying_data.present?
  end

  def friendly_name
    name || tag_identifying_data&.name
  end

  def try_friendly_name
    friendly_name || url_based_on_preferences
  end

  def url_based_on_preferences
    hostname_and_path
  end

  def has_image?
    tag_identifying_data&.image.present?
  end

  def try_image_url
    tag_identifying_data&.image&.url || 'https://cdn3.iconfinder.com/data/icons/online-marketing-line-3/48/109-512.png'
  end
  alias image_url try_image_url

  def hostname_and_path
    url_hostname + url_path
  end

  private

  def broadcast_new_tag_notification_to_all_users
    container.container_users.each do |container_user|
      container_user.user.broadcast_notification(
        partial: "/notifications/tags/new_tag",
        title: "🚨 New tag detected",
        image: try_image_url,
        partial_locals: { tag: self }
      )
    end
  end

  def check_to_sync_aws_event_bridge_rules_if_necessary
    if saved_changes['release_monitoring_interval_in_minutes']
      previous_release_monitoring_interval_in_minutes = saved_changes['release_monitoring_interval_in_minutes'][0]
      enable_aws_event_bridge_rules_for_release_check_interval_if_necessary!
      disable_aws_event_bridge_rules_if_no_release_checks_enabled_for_interval(previous_release_monitoring_interval_in_minutes)
    end
  end

  def disable_aws_event_bridge_rules_if_no_release_checks_enabled_for_interval(interval)
    return false if interval.nil? || interval.zero?
    return false if Tag.where(release_monitoring_interval_in_minutes: interval).any?
    ReleaseCheckScheduleAwsEventBridgeRule.for_interval!(interval).disable!
  end

  def enable_aws_event_bridge_rules_for_release_check_interval_if_necessary!
    return false if release_monitoring_disabled?
    ReleaseCheckScheduleAwsEventBridgeRule.for_interval!(release_monitoring_interval_in_minutes).enable!
  end

  def has_at_least_one_page_url_tag_found_on
    if page_urls_tag_found_on.none?
      errors.add(:base, "Tag must be associated with at least one PageUrl.")
    end
  end
end
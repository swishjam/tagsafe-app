class TagVersion < ApplicationRecord
  include Rails.application.routes.url_helpers
  include Notifier
  include Streamable
  acts_as_paranoid
  
  belongs_to :tag
  belongs_to :release_check_captured_with, class_name: ReleaseCheck.to_s
  has_many :audits, dependent: :destroy
  has_many :long_tasks, dependent: :destroy
  has_one_attached :js_file, service: :tag_version_s3
  has_one_attached :formatted_js_file, service: :tag_version_s3
  
  scope :most_recent, -> { where(most_recent: true) }
  # only time total_changes = nil is if theres not other version to compare to?
  # should we have a first class attribute for this?
  scope :first_version, -> { where(total_changes: nil) }
  scope :not_first_version, -> { where.not(total_changes: nil) }

  after_create :after_creation
  after_destroy { tag.tag_versions.most_recent_first.limit(1).first&.make_most_recent! unless tag.nil? }

  validate :has_attached_js_files
  validate :only_one_most_recent

  def after_creation
    set_script_last_released_at_timestamp
    make_most_recent!
    update_tag_table_row(tag: tag, now: true)
    add_tag_version_to_tag_details_view(tag_version: self, now: true)
    send_new_tag_version_notifications!
    unless tag.release_monitoring_disabled?
      NewTagVersionJob.perform_now(self)
    end
  end

  def sha
    hashed_content.slice(0, 8)
  end

  def make_most_recent!
    tag.most_recent_version.update!(most_recent: false) unless first_version? || tag.most_recent_version.nil?
    update!(most_recent: true)
  end

  def most_recent_version?
    most_recent
  end

  def send_new_tag_version_notifications!
    unless first_version?
      stream_notification_to_all_domain_users(
        domain: tag.domain,
        partial: "tag_versions/new_notification",
        partial_locals: { tag_version: self, domain: tag.domain },
        img: tag.try_image_url,
        timestamp: created_at.formatted_short
      )
      NewTagVersionAlert.create!(tag: tag, initiating_record: self)
    end
  end

  def perform_audit(execution_reason:, initiated_by_domain_user: nil, url_to_audit:, options: {})
    AuditRunner.new(
      tag_version: self,
      initiated_by_domain_user: initiated_by_domain_user,
      url_to_audit: url_to_audit,
      execution_reason: execution_reason,
      options: options
    ).run!
  end

  def perform_audit_on_all_urls(execution_reason:, initiated_by_domain_user: nil, options: {})
    tag.urls_to_audit.map do |url_to_audit| 
      perform_audit(
        url_to_audit: url_to_audit, 
        execution_reason: execution_reason, 
        initiated_by_domain_user: initiated_by_domain_user,
        options: options
      )
    end
  end

  def js_file_url(formatted: false, use_cloudfront_url: Util.env_is_true('USE_CLOUDFRONT_CDN_FOR_JS_FILES'))
    javascript_file = formatted ? formatted_js_file : js_file
    return javascript_file.url unless use_cloudfront_url
    parsed_url = URI.parse(javascript_file.url)
    parsed_url.hostname = ENV['CLOUDFRONT_TAG_VERSION_S3_HOSTNAME']
    parsed_url.to_s
  end

  def content(formatted: false)
    if formatted
      @formatted_content ||= formatted_js_file.download
    else
      @content ||= js_file.download
    end
  end

  def audit_to_display
    most_recent_successful_audit || most_recent_pending_audit || most_recent_failed_audit
  end

  def most_recent_successful_audit
    audits.most_recent_first.successful_performance_audit.limit(1).first
  end

  def most_recent_pending_audit
    audits.most_recent_first.pending.limit(1).first
  end

  def most_recent_failed_audit
    audits.most_recent_first.failed_performance_audit.limit(1).first
  end

  def has_pending_audit?
    audits.pending.any?
  end

  def should_throttle_audit?
    throttler.should_throttle?
  end

  def throttle_audit!
    throttler.throttle!
  end

  def throttler
    @throttler ||= AuditThrottler::Evaluator.new(self)
  end

  def primary_audit
    audits.primary.limit(1).first
  end

  def total_num_delta_performance_audits_performed_across_all_audits
    audits.includes(:performance_audit_configuration).collect{ |a| a.performance_audit_configuration.num_performance_audits_to_run }.inject(:+)
  end

  def tagsafe_score
    primary_audit&.preferred_delta_performance_audit&.tagsafe_score
  end

  def previous_version
    tag.tag_versions.most_recent_first.older_than(created_at).limit(1).first
  end

  def next_version
    tag.tag_versions.most_recent_first.more_recent_than(created_at).limit(1).first
  end

  def image_url
    tag.try_image_url
  end

  def set_script_last_released_at_timestamp
    tag.update(last_released_at: created_at)
  end

  def first_version?
    previous_version.nil?
  end
  alias is_first_version? first_version?

  def purge_js_file
    js_file.purge if js_file && js_file.persisted?
  end

  def bytesize
    bytes
  end

  def change_in_bytes
    bytes - previous_version.bytes unless previous_version.nil?
  end

  ###############
  # VALIDATIONS #
  ###############

  def only_one_most_recent
    if most_recent && tag.tag_versions.where(most_recent: true).count > 1
      errors.add(:base, "Cannot have multiple most_recent tag versions on a single tag.")
    end
  end

  def has_attached_js_files
    if js_file_url.nil? || formatted_js_file.nil?
      errors.add(:base, "Attached JS file is required")
    end
  end
end
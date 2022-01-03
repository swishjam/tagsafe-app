class TagVersion < ApplicationRecord
  include Rails.application.routes.url_helpers
  include Notifier
  acts_as_paranoid
  
  belongs_to :tag
  has_many :audits, dependent: :destroy
  has_one_attached :js_file, service: :tag_version_s3
  has_one_attached :tagsafe_instrumented_js_file, service: :tag_version_s3
  
  scope :most_recent, -> { where(most_recent: true) }

  broadcast_notification on: :create
  after_create :after_creation
  # after_destroy :purge_js_file

  validate :only_one_most_recent

  def after_creation
    set_script_content_changed_at_timestamp
    make_most_recent!
    tag.update_tag_row
    add_tag_version_to_tag_details_view
    NewTagVersionJob.perform_later(self)
  end

  def after_create_notification_msg
    "A new version of #{tag.try_friendly_name} has been detected."
  end

  # for Notifier
  def domain_id
    tag.domain_id
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

  def hosted_js_file_url(cloudfront_url = ENV['USE_CLOUDFRONT_CDN_FOR_JS_FILES'] == 'true')
    return js_file.url unless cloudfront_url
    parsed_url = URI.parse(js_file.url)
    parsed_url.hostname = ENV['CLOUDFRONT_TAG_VERSION_S3_HOSTNAME']
    parsed_url.to_s
  end

  def hosted_tagsafe_instrumented_js_file_url(cloudfront_url = ENV['USE_CLOUDFRONT_CDN_FOR_JS_FILES'] == 'true')
    return tagsafe_instrumented_js_file.url unless cloudfront_url
    parsed_url = URI.parse(tagsafe_instrumented_js_file.url)
    parsed_url.hostname = ENV['CLOUDFRONT_TAG_VERSION_S3_HOSTNAME']
    parsed_url.to_s
  end

  def perform_audit_later(execution_reason:, url_to_audit:, options: {})
    AuditRunner.new(
      audit: nil,
      tag_version: self,
      url_to_audit_id: url_to_audit.id,
      execution_reason: execution_reason,
      options: options
    ).run!
  end

  def perform_audit_later_on_all_urls(execution_reason, options = {})
    tag.urls_to_audit.each{ |url_to_audit| perform_audit_later(url_to_audit: url_to_audit, execution_reason: execution_reason, options: options) }
  end

  def audit_to_display
    primary_audit || most_recent_pending_audit || most_recent_failed_audit
  end

  def most_recent_pending_audit
    audits.pending.limit(1).first
  end

  def most_recent_failed_audit
    audits.failed.limit(1).first
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

  def tagsafe_score
    primary_audit&.delta_performance_audit&.tagsafe_score
  end

  def previous_version
    tag.tag_versions.most_recent_first.older_than(created_at).limit(1).first
  end

  def next_version
    tag.tag_versions.most_recent_first.more_recent_than(created_at).limit(1).first
  end

  def content
    @content ||= js_file.download
  end

  def tagsafe_instrumented_content
    @tagsafe_instrumented_content ||= tagsafe_instrumented_js_file.download
  end

  def image_url
    tag.try_image_url
  end

  def set_script_content_changed_at_timestamp
    tag.update(content_changed_at: created_at)
  end

  def first_version?
    previous_version.nil?
  end

  def purge_js_file
    js_file.purge if js_file && js_file.persisted?
  end

  def bytesize
    bytes
  end

  def change_in_bytes
    bytes - previous_version.bytes unless previous_version.nil?
  end

  ###################
  ## TURBO STREAMS ##
  ###################

  def add_tag_version_to_tag_details_view(now: false)
    broadcast_method = now ? :broadcast_prepend_to : :broadcast_prepend_later_to
    send(broadcast_method, 
      "tag_#{tag.uid}_details_view_stream",
      target: "tag_#{tag.uid}_tag_versions_table_rows",
      partial: 'server_loadable_partials/tag_versions/tag_version_row',
      locals: { tag_version: self, tag: tag, streamed: true }
    )
  end

  def update_primary_audit_pill(now: false)
    broadcast_method = now ? :broadcast_replace_to : :broadcast_replace_later_to
    send(broadcast_method, 
      "domain_#{tag.domain.uid}_monitor_center_view_stream", 
      target: "tag_version_#{uid}_primary_audit_pill", 
      partial: 'audits/primary_audit_for_tag_version_pill',
      locals: { tag_version: self, tag: tag, streamed: true }
    )
  end

  def update_tag_version_table_row(now: false)
    broadcast_method = now ? :broadcast_replace_to : :broadcast_replace_later_to
    send(broadcast_method, 
      "tag_#{tag.uid}_details_view_stream",
      target: "tag_version_#{uid}_row",
      partial: 'server_loadable_partials/tag_versions/tag_version_row',
      locals: { tag_version: self, tag: tag, streamed: true }
    )
  end

  ###############
  # VALIDATIONS #
  ###############

  def only_one_most_recent
    if most_recent && tag.tag_versions.where(most_recent: true).count > 1
      errors.add(:base, "Cannot have multiple most_recent tag versions on a single tag.")
    end
  end
end
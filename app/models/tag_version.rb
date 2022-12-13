class TagVersion < ApplicationRecord
  include Rails.application.routes.url_helpers
  include Notifier
  include Streamable
  acts_as_paranoid
  
  belongs_to :tag
  belongs_to :release_check_captured_with, class_name: ReleaseCheck.to_s, optional: true
  has_many :audits, dependent: :destroy
    
  # only time total_changes = nil is if theres not other version to compare to?
  # should we have a first class attribute for this?
  scope :first_version, -> { where(total_changes: nil) }
  scope :not_first_version, -> { where.not(total_changes: nil) }
  # scope :most_recent, -> { where(most_recent: true) }

  # after_create :after_creation
  after_create { tag.update!(last_released_at: self.created_at) }
  # after_create { AlertEvaluators::NewTagVersion.new(self).trigger_alerts_if_criteria_is_met! unless first_version? }
  after_create_commit :broadcast_notification_to_all_users # temporary until we re-visit alerts
  after_create { CurrentLiveTagVersionDecider.new(self).set_as_tags_live_version_if_criteria_is_met! unless first_version? }
  # after_destroy { tag.tag_versions.most_recent_first.limit(1).first&.make_most_recent! unless tag.nil? }
  after_destroy :purge_s3_files!

  def s3_url(use_cdn: true, formatted: false)
    url_host = use_cdn ? ENV['CLOUDFRONT_HOSTNAME'] : s3_bucket
    "https://#{url_host}#{s3_pathname(formatted: formatted)}"
  end
  alias js_file_url s3_url

  def s3_bucket
    "tagsafe-#{Rails.env}-tag-versions.s3-us-east-1.amazonaws.com"
  end

  def s3_pathname(formatted: false, strip_leading_slash: false)
    # if there's a leading slash in the S3 file name, the first directory is just '/', strip it so the directory is the instrumentation key
    unique_s3_file_name = "#{tag.hostname_and_path.gsub('.', '_').gsub('/', '_')}-#{uid}#{formatted ? '-formatted' : ''}"
    "#{strip_leading_slash ? '' : '/'}tags/#{tag.container.instrumentation_key}/#{unique_s3_file_name}.js"
  end
  alias js_file_pathname s3_pathname

  def sha
    hashed_content.slice(0, 8)
  end

  def make_most_recent!
    tag.most_recent_version.update!(most_recent: false) unless first_version? || tag.most_recent_version.nil?
    update!(most_recent: true)
  end

  # def most_recent_version?
  #   most_recent
  # end

  def perform_audit(execution_reason:, initiated_by_container_user: nil, url_to_audit:, options: {})
    AuditHandler::Runner.new(
      tag_version: self,
      initiated_by_container_user: initiated_by_container_user,
      url_to_audit: url_to_audit,
      execution_reason: execution_reason,
      options: options
    ).run!
  end

  def perform_audit_on_all_urls(execution_reason:, initiated_by_container_user: nil, options: {})
    tag.urls_to_audit.map do |url_to_audit| 
      perform_audit(
        url_to_audit: url_to_audit, 
        execution_reason: execution_reason, 
        initiated_by_container_user: initiated_by_container_user,
        options: options
      )
    end
  end

  def content(formatted: false)
    if formatted
      @formatted_content ||= HTTParty.get(js_file_url(formatted: true)).to_s
    else
      @content ||= HTTParty.get(js_file_url(formatted: false)).to_s
    end
  end

  def purge_s3_files!
    TagsafeAws::S3.delete_object_by_s3_url(s3_url(use_cdn: false, formatted: false))
    TagsafeAws::S3.delete_object_by_s3_url(s3_url(use_cdn: false, formatted: true))
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

  private

  def broadcast_notification_to_all_users
    tag.container.container_users.each do |container_user|
      container_user.user.broadcast_notification(
        partial: "/notifications/tag_versions/new_tag_version",
        title: "🚨 New release from #{tag.try_friendly_name || tag.url_based_on_preferences}",
        image: tag.try_image_url,
        partial_locals: { tag_version: self }
      )
    end
  end
end
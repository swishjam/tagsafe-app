class TagVersion < ApplicationRecord
  include Rails.application.routes.url_helpers
  include Notifier
  include Streamable
  acts_as_paranoid

  belongs_to :tag
  belongs_to :release_check_captured_with, 
              class_name: ReleaseCheck.to_s, 
              optional: true
  belongs_to :primary_audit, 
              class_name: Audit.to_s, 
              optional: true
  belongs_to :container_user_change_request_decisioned_by, 
              class_name: ContainerUser.to_s, 
              foreign_key: :container_user_id_change_request_decisioned_by, 
              optional: true
  belongs_to :live_tag_version_at_time_of_decision,
              class_name: TagVersion.to_s,
              optional: true
  has_one :tag_with_current_live_tag_version, 
            class_name: Tag.to_s, 
            foreign_key: :current_live_tag_version_id, 
            dependent: :restrict_with_error
  has_one :tag_with_most_recent_tag_version, 
            class_name: Tag.to_s, 
            foreign_key: :most_recent_tag_version_id, 
            dependent: :restrict_with_error
  has_many :audits, dependent: :destroy
    
  # should we have a first class attribute for this?
  scope :first_version, -> { where(total_changes: nil) }
  scope :not_first_version, -> { where.not(total_changes: nil) }

  scope :blocked_from_promoting_to_live, -> { where(blocked_from_promoting_to_live: true) }
  scope :currently_live, -> { Tag.includes(:current_live_tag_version) }

  scope :unable_to_minify, -> { where(tagsafe_minified_byte_size: -1) }
  scope :successfully_minified, -> { where.not(tagsafe_minified_byte_size: -1) }

  scope :change_request_decided, -> { not_first_version.where.not(change_request_decision: nil) }
  scope :change_request_decision_pending, -> { not_first_version.where(change_request_decision: nil) }

  validates :change_request_decision, inclusion: { in: [nil, 'approved', 'denied'] }

  #############
  # CALLBACKS #
  #############

  before_create { self.tag_version_identifier = generate_tag_version_identifier }
  after_create { tag.update!(last_released_at: self.created_at) unless first_version? }
  after_create { tag.perform_audit_on_all_should_audit_urls!(execution_reason: ExecutionReason.NEW_RELEASE, tag_version: self, initiated_by_container_user: nil) }
  after_create_commit { broadcast_change_request_notification_to_all_users unless first_version? } # temporary until we re-visit alerts
  # after_create_commit { prepend_tag_version_to_tag_details_view }
  after_destroy :purge_s3_files!
  after_destroy { tag.update!(most_recent_tag_version: previous_version) if is_tags_most_recent_tag_version? }
  after_update_commit { update_tag_details_view if saved_changes['primary_audit_id'] }

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

  def is_open_change_request?
    !change_request_decisioned? && is_tags_most_recent_tag_version? && !is_tags_current_live_tag_version?
  end

  def change_request_decisioned?
    change_request_decision.present?
  end

  def change_request_approved?
    change_request_decision == 'approved'
  end

  def change_request_denied?
    change_request_decision == 'denied'
  end

  def approve_change_request(container_user)
    decide_change_request('approved', container_user)
  end

  def deny_change_request(container_user)
    decide_change_request('denied', container_user)
  end
  
  def perform_audit(execution_reason:, page_url:, initiated_by_container_user: nil, options: {})
    Audit.run!(
      tag: tag, 
      tag_version: self, 
      page_url: page_url, 
      execution_reason: execution_reason,
      initiated_by_container_user: initiated_by_container_user
    )
  end

  def perform_audit_on_all_urls(execution_reason:, initiated_by_container_user: nil, options: {})
    tag.page_urls.map do |page_url| 
      perform_audit(
        page_url: page_url, 
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

  def audit_to_determine_promotability
    audits.find_by(execution_reason: ExecutionReason.NEW_RELEASE)
  end

  def can_promote_to_live?
    !is_tags_current_live_tag_version? && !primary_audit_is_pending? && primary_audit.tagsafe_score >= 80
  end
  
  def primary_audit_is_pending?
    primary_audit.nil?
  end

  def audit_to_display
    primary_audit || audit_to_determine_promotability || most_recent_successful_audit || most_recent_pending_audit || most_recent_failed_audit
  end

  def most_recent_successful_audit
    audits.most_recent_first.successful.limit(1).first
  end

  def most_recent_pending_audit
    audits.most_recent_first.pending.limit(1).first
  end

  def most_recent_failed_audit
    audits.most_recent_first.failed.limit(1).first
  end

  def previous_version
    tag.tag_versions.most_recent_first.older_than(created_at).limit(1).first
  end
  alias previous_tag_version previous_version

  def next_version
    tag.tag_versions.most_recent_first.more_recent_than(created_at).limit(1).first
  end
  alias next_tag_version next_version

  def image_url
    tag.try_image_url
  end

  def tagsafe_saved_bytes?
    bytes_saved_with_tagsafe_minification > 0
  end

  def bytes_saved_with_tagsafe_minification
    return 0 if tagsafe_minified_byte_size.negative?
    difference = original_content_byte_size - tagsafe_minified_byte_size
    return 0 if difference.negative?
    difference
  end

  def is_tags_current_live_tag_version?
    self.id == tag.current_live_tag_version_id
  end

  def is_tags_most_recent_tag_version?
    self.id == tag.most_recent_tag_version_id
  end

  def newer_than_current_live_version?
    return false if !tag.has_current_live_tag_version? || is_tags_current_live_tag_version?
    created_at > tag.current_live_tag_version.created_at 
  end

  def older_than_current_live_version?
    return false if !tag.has_current_live_tag_version? || is_tags_current_live_tag_version?
    created_at < tag.current_live_tag_version.created_at
  end

  def num_releases_from_live_version
    return 0 if is_tags_current_live_tag_version?
    range = older_than_current_live_version? ? 
              created_at..tag.current_live_tag_version.created_at : 
              tag.current_live_tag_version.created_at..created_at
    tag.tag_versions.where(created_at: range).where.not(id: id).count
  end

  def first_version?
    previous_version.nil?
  end
  alias is_first_version? first_version?

  def purge_js_file
    js_file.purge if js_file && js_file.persisted?
  end

  def captured_at
    return created_at if release_check_captured_with_id.nil?
    release_check_captured_with.created_at
  end

  private

  def decide_change_request(decision, container_user)
    if is_tags_current_live_tag_version?
      errors.add(:base, "Cannot approve/deny change request, this version is already live.")
      false
    elsif !is_tags_most_recent_tag_version?
      errors.add(:base, "There is a newer change request that must be approved/denied first.")
      false
    else
      update!(
        change_request_decision: decision, 
        change_request_decisioned_at: Time.current, 
        container_user_id_change_request_decisioned_by: container_user.id,
        live_tag_version_at_time_of_decision: tag.current_live_tag_version,
      )
      tag.set_current_live_tag_version_and_publish_instrumentation(self) if decision == 'approved'
    end
  end

  def generate_tag_version_identifier
    return 'v001' if first_version?
    integer = previous_version.tag_version_identifier.gsub("v", '').to_i + 1
    leading_zeroes = integer < 10 ? '00' : integer < 100 ? '0' : ''
    ['v', leading_zeroes, integer].join('')
  end

  def broadcast_change_request_notification_to_all_users
    tag.container.container_users.each do |container_user|
      container_user.user.broadcast_notification(
        title: "New pull request",
        message: "#{tag.tag_snippet.name} made a new change request.",
        cta_url: "/containers/#{tag.container.uid}/change_requests/#{uid}",
        cta_text: "Review",
        image: tag.try_image_url,
      )
    end
    if tag.is_tagsafe_hosted && is_open_change_request?
      broadcast_replace_to(
        "#{tag.container.uid}_change_requests_count_indicator_stream",
        target: "#{tag.container.uid}_change_requests_count_indicator",
        partial: 'change_requests/count_indicator',
        locals: {
          container_uid: tag.container.uid,
          open_change_requests_count: tag.container.tags.open_change_requests.count,
        }
      )
    end
  end

  def prepend_tag_version_to_tag_details_view
    broadcast_prepend_to(
      "tag_#{tag.uid}_details_view_stream",
      target: "tag_#{tag.uid}_tag_versions",
      partial: 'tag_versions/tag_version_row',
      locals: { 
        tag_version: self,
        streamed: true
      }
    )
  end

  def update_tag_details_view
    broadcast_replace_to(
      "tag_#{tag.uid}_details_view_stream",
      target: "tag_version_#{uid}_row",
      partial: "tag_versions/tag_version_row",
      locals: {
        tag_version: self,
        streamed: true
      }
    )
  end
end
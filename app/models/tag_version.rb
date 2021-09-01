class TagVersion < ApplicationRecord
  include Rails.application.routes.url_helpers
  include Notifier

  belongs_to :tag
  has_many :audits, dependent: :destroy
  has_one_attached :js_file
  
  scope :most_recent, -> { where(most_recent: true) }

  after_create_commit do
    tag.update_tag_content
    # if first_version?
    #   broadcast_replace_later_to "#{tag_id}_tag_empty_tag_versions_message",
    #                         target: "#{tag_id}_tag_empty_tag_versions_message",
    #                         partial: 'server_loadable_partials/tag_versions/index',
    #                         locals: { tag_versions: tag.tag_versions.page(1).per(10), tag: tag }
    # else
      add_tag_version_to_list
    # end
  end

  after_update_commit { update_tag_version_content }
  broadcast_notification on: :create

  after_create :after_creation
  after_destroy :purge_js_file

  validate :only_one_most_recent

  def after_creation
    set_script_content_changed_at_timestamp
    make_most_recent!
    NewTagVersionJob.perform_later(self)
  end

  def update_tag_version_content
    broadcast_replace_later_to "#{tag_id}_tag_tag_versions", partial: 'server_loadable_partials/tag_versions/tag_version', locals: { tag_version: self }
    # in order to recalculate the change in performance score
    unless next_version.nil?
      broadcast_replace_later_to "#{next_version.id}_tag_tag_versions", partial: 'server_loadable_partials/tag_versions/tag_version', locals: { tag_version: self }
    end
  end

  def add_tag_version_to_list
    broadcast_prepend_later_to "#{tag_id}_tag_tag_versions",
                                target: "#{tag_id}_tag_tag_versions",
                                partial: 'server_loadable_partials/tag_versions/tag_version',
                                locals: { tag_version: self }
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

  def google_cloud_js_file_url
    url = URI.parse(js_file.service_url)
    url.fragment = url.query = nil
    url.to_s
  end

  def run_audit!(execution_reason, num_attempts: 0)
    AuditRunner.new(
      tag_version: self,
      execution_reason: execution_reason,
      num_attempts: num_attempts
    ).run!
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

  def previous_version
    tag.tag_versions.most_recent_first.older_than(created_at).limit(1).first
  end

  def next_version
    tag.tag_versions.most_recent_first.more_recent_than(created_at).limit(1).first
  end

  def content
    @content ||= js_file.download
  end

  def image_url
    tag.try_image_url
  end

  # this is dangerous because it's fetching the current tag content and not the snapshot at the time of the tag version, we're SOL for retroactively getting tag content
  # def __update_js_content!
  #   TagManager::Evaluator.new(tag).update_tag_version!(self)
  # end

  def set_script_content_changed_at_timestamp
    tag.update(content_changed_at: created_at)
  end

  def megabytes
    bytes / (1024.0 * 1024.0)
  end

  def first_version?
    previous_version.nil?
  end

  def purge_js_file
    js_file.purge if js_file && js_file.persisted?
  end

  def change_in_bytes
    bytes - previous_version.bytes unless previous_version.nil?
  end

  def byte_change_operator
    unless previous_version.nil?
      return 'did not change' if change_in_bytes.zero?
      change_in_bytes > 0 ? 'increased' : 'decreased'
    end
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
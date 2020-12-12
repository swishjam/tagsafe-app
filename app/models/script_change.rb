class ScriptChange < ApplicationRecord
  include Rails.application.routes.url_helpers

  belongs_to :script
  has_many :audits, dependent: :destroy
  has_one_attached :js_file
  
  scope :most_recent, -> { where(most_recent: true) }

  # very hacky to allow us to seed DB without resulting background jobs,
  after_create do
    after_creation unless ScriptChange.skip_callbacks
  end
  after_destroy :purge_js_file

  validate :only_one_most_recent

  def after_creation
    set_script_content_changed_at_timestamp
    make_most_recent!
    ScriptChangedJob.perform_later(self)
  end

  def version
    hashed_content.slice(0, 8)
  end

  def make_most_recent!
    script.most_recent_change.update!(most_recent: false) unless first_change? || script.most_recent_change.nil?
    update!(most_recent: true)
  end

  def js_file_path(only_path = true)
    rails_blob_path(js_file.attachment, only_path: only_path)
  end

  def js_file_url
    rails_blob_url(js_file.attachment, host: ENV['HOST'])
  end

  def primary_audit
    audits.primary.first
  end

  def is_most_recent_change?
    !script.script_changes.newer_than(created_at).any?
  end

  def previous_change
    script.script_changes.most_recent_first.older_than(created_at).limit(1).first
  end
  alias previous_result previous_change

  def content
    @content ||= js_file.download
  end

  def set_script_content_changed_at_timestamp
    script.update(content_changed_at: created_at)
  end

  def megabytes
    bytes / (1024.0 * 1024.0)
  end

  def first_change?
    previous_change.nil?
  end

  def purge_js_file
    js_file.purge
  end

  def change_in_bytes
    bytes - previous_change.bytes unless previous_change.nil?
  end

  def byte_change_operator
    unless previous_change.nil?
      return 'did not change' if change_in_bytes.zero?
      change_in_bytes > 0 ? 'increased' : 'decreased'
    end
  end

  ###############
  # VALIDATIONS #
  ###############

  def only_one_most_recent
    if most_recent_changed? && most_recent && script.script_changes.where(most_recent: true).count > 1
      errors.add(:base, "Cannot have multiple most_recent script changes on a single script.")
    end
  end
end
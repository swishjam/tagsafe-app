# class Tag < ApplicationRecord
#   include Rails.application.routes.url_helpers
  
#   belongs_to :script_image, optional: true
#   has_many :tags, dependent: :destroy
#   has_many :domains, through: :tags
#   has_many :tag_versions, -> { order('created_at DESC') }, dependent: :destroy
#   has_many :script_checks, dependent: :destroy
  
#   has_many :new_tag_version_email_subscribers, through: :tags
#   has_many :audit_complete_notification_subscribers, through: :tags

#   has_many :tag_versiond_slack_notifications, through: :tags
#   has_many :audit_completed_slack_notifications, through: :tags
#   has_many :audit_complete_notification_subscribers, through: :tags
#   has_many :new_tag_slack_notifications, through: :tags
  
#   has_one_attached :image

#   after_create :try_to_apply_script_image

#   validates :url, presence: true, uniqueness: true
#   # validate :valid_url

#   scope :one_minute_interval_checks, -> { self.all }
#   scope :five_minute_interval_checks, -> { self.all }
#   # etc...
#   scope :with_active_subscribers, -> { includes(:tags).where(tags: { monitor_changes: true }) }
#   scope :still_on_site, -> { includes(:tags).where(tags: { removed_from_site_at: nil }) }
#   scope :monitor_changes, -> { includes(:tags).where(tags: { monitor_changes: true }) }
#   scope :should_run_audit, -> { includes(tags: [:performance_audit_preferences]).where(tags: { performance_audit_preferences: { should_run_audit: true }} ) }
#   scope :should_log_script_checks, -> { where(should_log_script_checks: true) }

#   def most_recent_result
#     tag_versions.where(most_recent: true).limit(1).first
#   end
#   alias most_recent_version most_recent_result
#   alias most_recent_tag_version most_recent_result

#   def current_js_file_path
#     most_recent_result.js_file_path
#   end

#   def has_no_versions?
#     most_recent_result.nil?
#   end

#   # do we want this in an after_create callback? or trust the UpdateDomainsTagsJob to be the only place to create scripts
#   def capture_tag_content
#     # make sure to return the evaluator so we can read the results afterwards
#     evaluator = TagManager::Evaluator.new(self)
#     evaluator.evaluate!
#     evaluator
#   end

#   def try_to_apply_script_image
#     TagImageDomainLookupPattern.find_and_apply_image_to_tag(self)
#   end

#   # def remove_script_image
#   #   update(script_image_id: nil)
#   # end

#   def try_image_url
#     script_image ? rails_blob_url(script_image.image, host: ENV['CURRENT_HOST']) : default_image_url
#     # script_image ? rails_blob_path(script_image.image, only_path: only_path) : default_image_url
#   end

#   def default_image_url
#     'https://cdn3.iconfinder.com/data/icons/online-marketing-line-3/48/109-512.png'
#   end

#   def friendly_name
#     name || full_url
#   end

#   def change_in_bytes
#     most_recent_result.bytes - most_recent_result.previous_result.bytes unless most_recent_result.nil?
#   end

#   def pretty_last_changed_at
#     most_recent_version.created_at.strftime("%A, %B%e @%l:%M %p (%Z)")
#   end

#   def url
#     full_url
#   end

#   ###############
#   # Validations #
#   ###############
#   def valid_url
#     TagManager::Fetcher.new(url).fetch!
#   rescue => e
#     errors.add(:url, "error. Unable to connect to #{url}. URL must return a valid response.")
#   end
# end
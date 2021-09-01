class EmailNotificationSubscriber < ApplicationRecord
  belongs_to :tag
  belongs_to :user

  scope :still_on_site, -> { joins(tag: :tag_preferences).where(tags: { tag_preferences: { removed_from_site_at: nil }}) }
  scope :monitor_changes, -> { joins(tag: :tag_preferences).where(tags: { tag_preferences: { monitor_changes: true }}) }
  scope :should_receive_notifications, -> { monitor_changes.still_on_site }

  validates_uniqueness_of :tag_id, scope: [:user_id, :type]
end
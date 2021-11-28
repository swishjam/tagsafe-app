class EmailNotificationSubscriber < ApplicationRecord
  belongs_to :tag
  belongs_to :user

  scope :still_on_site, -> { joins(tag: :tag_preferences).where(tags: { tag_preferences: { removed_from_site_at: nil }}) }
  scope :enabled, -> { joins(tag: :tag_preferences).where(tags: { tag_preferences: { enabled: true }}) }
  scope :should_receive_notifications, -> { enabled.still_on_site }

  validates_uniqueness_of :tag_id, scope: [:user_id, :type]
end
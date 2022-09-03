class EmailNotificationSubscriber < ApplicationRecord
  belongs_to :tag
  belongs_to :user

  scope :enabled, -> { joins(tag: :live_tag_configuration).where(tags: { live_tag_configuration: { enabled: true }}) }

  validates_uniqueness_of :tag_id, scope: [:user_id, :type]
end
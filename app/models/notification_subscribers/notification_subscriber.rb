class NotificationSubscriber < ApplicationRecord
  belongs_to :script_subscriber
  belongs_to :user

  scope :active, -> { joins(:script_subscriber).where(script_subscribers: { active: true }) }
  scope :still_on_site, -> { joins(:script_subscriber).where(script_subscribers: { removed_from_site_at: nil }) }

  validates_uniqueness_of :script_subscriber_id, scope: [:user_id, :type]
end
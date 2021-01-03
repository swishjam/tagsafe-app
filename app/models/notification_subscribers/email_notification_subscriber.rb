class EmailNotificationSubscriber < ApplicationRecord
  belongs_to :script_subscriber
  belongs_to :user

  scope :still_on_site, -> { joins(:script_subscriber).where(script_subscribers: { removed_from_site_at: nil }) }
  scope :monitor_changes, -> { joins(:script_subscriber).where(script_subscribers: { monitor_changes: true }) }
  scope :should_receive_notifications, -> { monitor_changes.still_on_site }

  validates_uniqueness_of :script_subscriber_id, scope: [:user_id, :type]
end
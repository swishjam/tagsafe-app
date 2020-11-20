class NotificationSubscriber < ApplicationRecord
  belongs_to :script_subscriber
  belongs_to :user

  validates_uniqueness_of :script_subscriber_id, scope: [:user_id, :type]
end
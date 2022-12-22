class EmailNotificationSubscriber < ApplicationRecord
  belongs_to :tag
  belongs_to :user

  scope :enabled, -> { all }

  validates_uniqueness_of :tag_id, scope: [:user_id, :type]
end
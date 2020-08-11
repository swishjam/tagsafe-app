class NotificationSubscriber < ApplicationRecord
  belongs_to :monitored_script
  belongs_to :user
end
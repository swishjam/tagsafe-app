class User < ApplicationRecord
  has_secure_password

  belongs_to :organization
  has_many :notification_subscribers

  validates :email, presence: true, uniqueness: true

  def subscribed?(monitored_script)
    notification_subscribers.collect(&:monitored_script_id).include? monitored_script.id
  end

  def subscribe!(monitored_script)
    notification_subscribers.create(monitored_script: monitored_script)
  end

  def unsubscribe!(monitored_script)
    notification_subscribers.find_by(monitored_script_id: monitored_script.id).destroy
  end
end
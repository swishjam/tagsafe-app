class FailedTestNotificationSubscriber < EmailNotificationSubscriber
  def self.friendly_name
    'failed test'
  end
end
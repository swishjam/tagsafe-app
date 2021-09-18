class NewTagVersionSlackNotification < SlackNotificationSubscriber
  # 

  def friendly_name
    'On Tag Changes'
  end

  def notify!(tag_version)
    slack_client.notify!(message: message, channel: channel)
  end

  def message
    "#{tag.try_friendly_name} has changed. Audit is currently running."
  end
end
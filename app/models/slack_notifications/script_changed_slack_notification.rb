class ScriptChangedSlackNotification < SlackNotificationSubscriber
  def friendly_name
    'On Script Changes'
  end

  def notify!(script_change)
    slack_client.notify!(message: message(script_change), channel: channel)
  end

  def message(script_change)
    "#{script_subscriber.try_friendly_name} has changed. Audit is currently running."
  end
end
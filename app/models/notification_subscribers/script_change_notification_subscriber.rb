class ScriptChangeNotificationSubscriber < NotificationSubscriber
  def self.friendly_name
    'script changed'
  end

  def send_email!(script_change)
    ScriptChangeMailer.send_script_changed_email(user, script_subscriber, script_change).deliver
  end
end
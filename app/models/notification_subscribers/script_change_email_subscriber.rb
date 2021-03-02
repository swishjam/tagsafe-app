class ScriptChangeEmailSubscriber < EmailNotificationSubscriber
  def self.friendly_name
    'script changed'
  end

  def send_email!(script_change)
    TagSafeMailer.send_script_changed_email(user, script_subscriber, script_change)
  end
end
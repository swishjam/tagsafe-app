class NotificationManager::Notifier
  def initialize(script_change)
    @script_change = script_change
  end

  def notify_all!
    @script_change.monitored_script.notification_subscribers.each do |subscriber|
      ScriptChangeMailer.send_script_changed_email(subscriber.user, @script_change).deliver
    end
  end
end
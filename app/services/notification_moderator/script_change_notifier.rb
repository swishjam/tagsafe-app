module NotificationModerator
  class ScriptChangeNotifier
    def initialize(script_change)
      @script_change = script_change
    end

    def notify!
      notify_email_subscribers
      notify_slack_subscribers
    end

    private

    def notify_email_subscribers
      @script_change.script.script_change_email_subscribers.should_receive_notifications.each do |email_subscriber|
        email_subscriber.send_email!(self) unless email_subscriber.script_subscriber.first_script_change == self
      end
    end

    def notify_slack_subscribers
      @script_change.script.script_changed_slack_notifications.should_receive_notifications.each do |slack_notification|
        slack_notification.notify!(self) unless slack_notification.script_subscriber.first_script_change == self
      end
    end
  end
end
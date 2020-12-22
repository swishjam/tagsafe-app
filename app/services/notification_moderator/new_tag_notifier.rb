module NotificationModerator
  class NewTagNotifier
    def initialize(script_subscriber)
      @script_subscriber = script_subscriber
    end

    def notify!
      notify_email_subscribers
      notify_slack_subscribers
    end

    def notify_email_subscribers
      @script_subscriber.domain.organization.users.each do |user|
        TagSafeMailer.send_new_tag_detected_email(user, script_subscriber)
      end
    end

    def notify_slack_subscribers
      @script_subscriber.new_tag_slack_notifications.should_receive_notifications.each do |slack_notifier|
        slack_notifier.notify!(@script_subscriber)
      end
    end
  end
end
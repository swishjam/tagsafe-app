module NotificationModerator
  class NewTagNotifier
    def initialize(tag)
      @tag = tag
    end

    def notify!
      notify_email_subscribers
      notify_slack_subscribers
    end

    def notify_email_subscribers
      # @tag.domain.users.each do |user|
        # TagsafeMailer.send_new_tag_detected_email(user, @tag)
      # end
    end

    def notify_slack_subscribers
      # @tag.new_tag_slack_notifications.should_receive_notifications.each do |slack_notifier|
      #   slack_notifier.notify!(@tag)
      # end
    end
  end
end
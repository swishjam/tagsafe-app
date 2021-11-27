module NotificationModerator
  class NewTagVersionNotifier
    def initialize(tag_version)
      @tag_version = tag_version
    end

    def notify!
      unless @tag_version.first_version?
        notify_email_subscribers
        notify_slack_subscribers
      end
    end

    private

    def notify_email_subscribers
      # TODO: rework this to only send to email subscribers, not all organization users
      @tag_version.tag.domain.organization.users.each do |user|
        TagSafeMailer.send_new_tag_version_email(user, @tag_version.tag, @tag_version)
      end
      # @tag_version.tag.new_tag_version_email_subscribers.should_receive_notifications.each do |email_subscriber|
      #   email_subscriber.send_email!(self)
      # end
    end

    def notify_slack_subscribers
      # @tag_version.tag.new_tag_version_slack_notifications.should_receive_notifications.each do |slack_notification|
      #   slack_notification.notify!(self)
      # end
    end
  end
end
class ChangeSlackAndEmailSubscriberNames < ActiveRecord::Migration[5.2]
  def change
    rename_table :notification_subscribers, :email_notification_subscribers
    rename_table :slack_notifications, :slack_notification_subscribers
  end
end

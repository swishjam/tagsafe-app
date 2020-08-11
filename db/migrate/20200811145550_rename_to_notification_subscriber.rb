class RenameToNotificationSubscriber < ActiveRecord::Migration[5.2]
  def change
    rename_table :script_notification_subscribers, :notification_subscribers
  end
end

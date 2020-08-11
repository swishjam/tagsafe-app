class UpdateScriptNotificationSubscriberRelation < ActiveRecord::Migration[5.2]
  def change
    rename_column :script_notification_subscribers, :script_subscriber_id, :monitored_script_id
  end
end

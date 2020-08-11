class UpdateScriptSubscribersTableName < ActiveRecord::Migration[5.2]
  def up
    rename_table :script_subscribers, :monitored_scripts_organizations
    rename_table :script_subscribers_users, :script_notification_subscribers
  end
end

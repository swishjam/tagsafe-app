class CreateScriptSubscriberJoinTable < ActiveRecord::Migration[5.2]
  def up
    create_table :notification_subscribers do |t|
      t.integer :script_subscriber_id
      t.integer :user_id

      t.timestamps
    end
  end
end

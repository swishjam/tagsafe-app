class AddNotificationSubscriptions < ActiveRecord::Migration[5.2]
  def up
    create_table :notification_subscribers do |t|
      t.string :type
      t.integer :user_id
      t.integer :tag_id
    end
  end

  def down
    drop_table :notification_subscribers
  end
end

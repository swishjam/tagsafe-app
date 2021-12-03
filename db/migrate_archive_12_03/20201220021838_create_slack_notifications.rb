class CreateSlackNotifications < ActiveRecord::Migration[5.2]
  def change
    create_table :slack_notifications do |t|
      t.integer :tag_id
      t.string :type
      t.string :channel
    end
  end
end

class RemoveTimestampsFromBlockedResources < ActiveRecord::Migration[6.1]
  def up
    remove_column :blocked_resources, :created_at
    remove_column :blocked_resources, :updated_at

    remove_column :tag_preferences, :enabled
    remove_column :tag_preferences, :url_to_audit
    remove_column :tags, :friendly_name
  end

  def down
  end
end

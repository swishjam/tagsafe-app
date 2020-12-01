class AddRemovedFromSiteAtToScriptSubscribers < ActiveRecord::Migration[5.2]
  def change
    add_column :script_subscribers, :removed_from_site_at, :timestamp
  end
end

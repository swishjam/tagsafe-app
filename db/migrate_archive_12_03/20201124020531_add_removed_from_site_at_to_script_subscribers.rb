class AddRemovedFromSiteAtToTags < ActiveRecord::Migration[5.2]
  def change
    add_column :tags, :removed_from_site_at, :timestamp
  end
end

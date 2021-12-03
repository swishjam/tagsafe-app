class AddMostRecentFlagToTagVersions < ActiveRecord::Migration[5.2]
  def change
    add_column :tag_versions, :most_recent, :boolean
  end
end

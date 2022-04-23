class AddGitColumnsToTagVersion < ActiveRecord::Migration[6.1]
  def up
    add_column :tag_versions, :total_changes, :integer
    add_column :tag_versions, :num_additions, :integer
    add_column :tag_versions, :num_deletions, :integer
    add_column :tag_versions, :commit_message, :text
  end

  def down
    remove_column :tag_versions, :total_changes, :integer
    remove_column :tag_versions, :num_additions, :integer
    remove_column :tag_versions, :num_deletions, :integer
    remove_column :tag_versions, :commit_message, :text
  end
end

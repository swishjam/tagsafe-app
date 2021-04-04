class AddTagVersionAndTagCheckRetention < ActiveRecord::Migration[5.2]
  def change
    add_column :tags, :tag_version_retention_count, :integer
    add_column :tags, :script_check_retention_count, :integer
  end
end

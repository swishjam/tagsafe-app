class AddBytesToScripChanges < ActiveRecord::Migration[5.2]
  def up
    add_column :tag_versions, :bytes, :integer
  end

  def down
    remove_column :tag_versions, :bytes
  end
end

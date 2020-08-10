class AddBytesToScripChanges < ActiveRecord::Migration[5.2]
  def up
    add_column :script_changes, :bytes, :integer
  end

  def down
    remove_column :script_changes, :bytes
  end
end

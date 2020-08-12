class ChangeScriptChangeTextToLongText < ActiveRecord::Migration[5.2]
  def change
    change_column :script_changes, :content, :mediumtext
  end
end

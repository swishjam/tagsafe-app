class ChangeScriptChangeTextToLongText < ActiveRecord::Migration[5.2]
  def change
    change_column :script_changes, :content, :longtext
  end
end

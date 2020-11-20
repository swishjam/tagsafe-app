class AddMostRecentFlagToScriptChanges < ActiveRecord::Migration[5.2]
  def change
    add_column :script_changes, :most_recent, :boolean
  end
end

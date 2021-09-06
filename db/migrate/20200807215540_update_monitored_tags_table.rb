class UpdateMonitoredTagsTable < ActiveRecord::Migration[5.2]
  def up
    add_column :monitored_scripts, :name, :string
    add_column :monitored_scripts, :script_last_updated_at, :timestamp
  end

  def down
    remove_column :monitored_scripts, :name
    remove_column :monitored_scripts, :script_last_updated_at
  end
end

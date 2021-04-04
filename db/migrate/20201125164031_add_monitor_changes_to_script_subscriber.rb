class AddMonitorChangesToTag < ActiveRecord::Migration[5.2]
  def change
    add_column :tags, :monitor_changes, :boolean
  end
end

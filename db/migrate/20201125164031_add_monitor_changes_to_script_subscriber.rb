class AddMonitorChangesToScriptSubscriber < ActiveRecord::Migration[5.2]
  def change
    add_column :script_subscribers, :monitor_changes, :boolean
  end
end

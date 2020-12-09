class AddTimestampstoScriptSubscriber < ActiveRecord::Migration[5.2]
  def change
    add_column :script_subscribers, :created_at, :timestamp, default: 'CURRENT_TIMESTAMP'
  end
end

class AddScriptChangeAndScriptCheckRetention < ActiveRecord::Migration[5.2]
  def change
    add_column :script_subscribers, :script_change_retention_count, :integer
    add_column :script_subscribers, :script_check_retention_count, :integer
  end
end

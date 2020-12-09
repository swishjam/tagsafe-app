class AddFirstScriptChangeToScriptSubscriber < ActiveRecord::Migration[5.2]
  def change
    add_column :script_subscribers, :first_script_change_id, :integer
  end
end

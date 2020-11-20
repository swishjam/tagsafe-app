class AddFriendlyNameToScriptSubscriber < ActiveRecord::Migration[5.2]
  def change
    add_column :script_subscribers, :friendly_name, :string
  end
end

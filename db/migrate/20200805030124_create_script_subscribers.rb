class CreateScriptSubscribers < ActiveRecord::Migration[5.2]
  def change
    create_table :monitored_scripts_organizations do |t|
      t.integer :organization_id
      t.integer :monitored_script_id
    end
  end
end

class CreateScriptChangeSubscriber < ActiveRecord::Migration[5.2]
  def change
    create_table :script_change_subscribers do |t|
      t.references :user
      t.references :script_subscriber
    end
  end
end

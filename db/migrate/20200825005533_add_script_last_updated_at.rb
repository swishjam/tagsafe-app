class AddScriptLastUpdatedAt < ActiveRecord::Migration[5.2]
  def up
    add_column :scripts, :content_changed_at, :timestamp
  end
end

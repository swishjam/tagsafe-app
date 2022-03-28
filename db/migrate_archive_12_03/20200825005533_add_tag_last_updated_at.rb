class AddTagLastUpdatedAt < ActiveRecord::Migration[5.2]
  def up
    add_column :scripts, :last_released_at, :timestamp
  end
end

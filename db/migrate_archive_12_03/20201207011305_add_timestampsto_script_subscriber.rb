class AddTimestampstoTag < ActiveRecord::Migration[5.2]
  def change
    add_column :tags, :created_at, :timestamp, default: 'CURRENT_TIMESTAMP'
  end
end

class AddMonitorChangesToTag < ActiveRecord::Migration[5.2]
  def change
    add_column :tags, :enabled, :boolean
  end
end

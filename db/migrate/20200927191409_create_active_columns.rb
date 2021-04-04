class CreateActiveColumns < ActiveRecord::Migration[5.2]
  def change
    remove_column :tags, :live
    add_column :tags, :active, :boolean
    add_column :test_subscribers, :active, :boolean
  end
end

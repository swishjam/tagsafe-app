class CreateActiveColumns < ActiveRecord::Migration[5.2]
  def change
    remove_column :script_subscribers, :live
    add_column :script_subscribers, :active, :boolean
    add_column :test_subscribers, :active, :boolean
  end
end

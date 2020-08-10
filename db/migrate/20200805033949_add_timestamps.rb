class AddTimestamps < ActiveRecord::Migration[5.2]
  def up
    add_column :users, :created_at, :datetime, null: false
    add_column :users, :updated_at, :datetime, null: false

    add_column :script_changes, :created_at, :datetime, null: false
    add_column :script_changes, :updated_at, :datetime, null: false

    add_column :monitored_scripts, :created_at, :datetime, null: false
    add_column :monitored_scripts, :updated_at, :datetime, null: false

    add_column :organizations, :created_at, :datetime, null: false
    add_column :organizations, :updated_at, :datetime, null: false
  end

  def down
    remove_column :users, :created_at
    remove_column :users, :updated_at

    remove_column :script_changes, :created_at
    remove_column :script_changes, :updated_at

    remove_column :monitored_scripts, :created_at
    remove_column :monitored_scripts, :updated_at

    remove_column :organizations, :created_at
    remove_column :organizations, :updated_at
  end
end

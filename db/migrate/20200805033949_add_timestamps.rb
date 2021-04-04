class AddTimestamps < ActiveRecord::Migration[5.2]
  def up
    add_column :users, :created_at, :datetime, null: false
    add_column :users, :updated_at, :datetime, null: false

    add_column :tag_versions, :created_at, :datetime, null: false
    add_column :tag_versions, :updated_at, :datetime, null: false

    add_column :monitored_scripts, :created_at, :datetime, null: false
    add_column :monitored_scripts, :updated_at, :datetime, null: false

    add_column :organizations, :created_at, :datetime, null: false
    add_column :organizations, :updated_at, :datetime, null: false
  end

  def down
    remove_column :users, :created_at
    remove_column :users, :updated_at

    remove_column :tag_versions, :created_at
    remove_column :tag_versions, :updated_at

    remove_column :monitored_scripts, :created_at
    remove_column :monitored_scripts, :updated_at

    remove_column :organizations, :created_at
    remove_column :organizations, :updated_at
  end
end

class InitialMigration < ActiveRecord::Migration[5.2]
  def up
    create_table :organizations do |t|
      t.string :name
    end

    create_table :users do |t|
      t.integer :organization_id

      t.string :email
      t.string :password
    end

    create_table :monitored_scripts do |t|
      t.string :url
    end

    create_table :tag_versions do |t|
      t.integer :monitored_script_id
      
      t.string :hashed_content
      t.longtext :content
    end
  end

  def down
    drop_table :users
    drop_table :tag_versions
    drop_table :monitored_scripts
    drop_table :organizations
  end
end

class FreshDb < ActiveRecord::Migration[5.2]
  def up
    drop_table :monitored_scripts
    drop_table :tag_versions
    drop_table :monitored_scripts_organizations
    drop_table :notification_subscribers

    create_table :domains do |t|
      t.references :organization
      t.string :url

      t.timestamps
      t.index [:url]
    end

    create_table :scripts do |t|
      t.string :url
      t.string :name

      t.timestamps
      t.index [:url]
    end

    create_join_table :domains, :scripts do |t|
      t.index [:domain_id, :script_id]
    end

    create_table :tag_versions do |t|
      t.references :script
      t.has_attached_file :js_file
      t.integer :bytes
      t.string :hashed_content

      t.timestamps
    end

    create_table :tag_version_subcribers do |t|
      t.references :script
      t.references :user
    end

    create_table :tests do |t|
      t.mediumtext :test_script
    end

    create_join_table :scripts, :tests do |t|
      t.index [:script_id, :test_id]
    end

    create_join_table :domains, :tests do |t|
      t.index [:domain_id, :test_id]
    end

    create_table :test_results do |t|
      t.references :test
      t.references :tag_version
      t.boolean :passed
      t.string :result
    end

    create_table :test_result_subscribers do |t|
      t.references :user
      t.references :test
    end
    # organizations
    # roles
    # roles_users
    # users   
  end

  def down 
  end
end

class CreateTagConfigurations < ActiveRecord::Migration[6.1]
  def up
    create_table :tag_configurations do |t|
      t.string :uid, index: true
      t.references :tag
      t.string :type
      t.integer :release_check_minute_interval
      t.integer :scheduled_audit_minute_interval
      t.string :load_type
      t.boolean :is_tagsafe_hosted
      t.integer :script_inject_priority
      t.string :script_inject_location
      t.string :script_inject_event
      t.boolean :execute_script_in_web_worker
      t.boolean :enabled
      t.timestamps
    end

    drop_table :tag_preferences

    remove_column :tags, :load_type
    remove_column :tags, :has_content
    remove_column :tags, :last_seen_in_url_crawl_at
    remove_column :tags, :is_tagsafe_hosted
    remove_column :tags, :script_inject_priority
    remove_column :tags, :script_inject_location
    remove_column :tags, :script_inject_is_disabled
    remove_column :tags, :execute_script_in_web_worker
    remove_column :tags, :script_inject_event
    remove_column :tags, :is_draft

    remove_column :tags, :removed_from_site_at
    remove_column :tags, :found_on_page_url_id
    remove_column :tags, :found_on_url_crawl_id
    remove_column :tags, :tag_image_id
  end
end

class AddTagLoadPriorityAndPlacement < ActiveRecord::Migration[6.1]
  def up
    add_column :tags, :js_script, :longtext
    add_column :tags, :script_inject_priority, :integer
    add_column :tags, :script_inject_location, :string
    add_column :tags, :script_inject_is_disabled, :boolean
    add_column :tags, :execute_script_in_web_worker, :boolean
    add_column :tags, :script_inject_event, :string
    add_reference :tags, :current_live_tag_version

    add_column :tag_versions, :sha_256, :string
    add_column :tag_versions, :tag_version_identifier, :string
  end

  def down
    remove_column :tags, :js_script
    remove_column :tags, :script_inject_priority
    remove_column :tags, :script_inject_location
    remove_column :tags, :script_inject_is_disabled
    remove_column :tags, :execute_script_in_web_worker
    remove_column :tags, :script_inject_event
    remove_column :tags, :current_live_tag_version_id
    
    remove_column :tag_versions, :sha_256
    remove_column :tag_versions, :tag_version_identifier
  end
end

class TagPreferences < ActiveRecord::Migration[5.2]
  def change
    rename_table :performance_audit_preferences, :tag_preferences
    
    remove_column :tags, :enabled
    remove_column :tags, :is_allowed_third_party_tag
    remove_column :tags, :is_third_party_tag
    remove_column :tags, :should_log_tag_checks
    remove_column :tags, :consider_query_param_changes_new_tag
    remove_column :tags, :should_run_audit
    remove_column :tags, :throttle_minute_threshold

    add_column :tag_preferences, :enabled, :boolean
    add_column :tag_preferences, :is_allowed_third_party_tag, :boolean
    add_column :tag_preferences, :is_third_party_tag, :boolean
    add_column :tag_preferences, :should_log_tag_checks, :boolean
    add_column :tag_preferences, :consider_query_param_changes_new_tag, :boolean
    add_column :tag_preferences, :throttle_minute_threshold, :integer
  end
end

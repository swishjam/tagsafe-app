class SimplifyTagsToOnlyEnabled < ActiveRecord::Migration[6.1]
  def change
    remove_column :tag_preferences, :should_run_audit
    rename_column :tag_preferences, :monitor_changes, :enabled
  end
end

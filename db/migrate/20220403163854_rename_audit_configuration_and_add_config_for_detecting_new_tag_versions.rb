class RenameAuditGeneralConfigurationAndAddConfigForDetectingNewTagVersions < ActiveRecord::Migration[6.1]
  def up
    rename_table :default_audit_configurations, :general_configurations
    add_column :configurations, :num_recent_tag_versions_to_compare_in_release_monitoring, :integer
  end

  def down
  end
end

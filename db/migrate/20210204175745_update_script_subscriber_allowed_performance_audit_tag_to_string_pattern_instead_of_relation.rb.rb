class UpdateScriptSubscriberAllowedPerformanceAuditTagToStringPatternInsteadOfRelation < ActiveRecord::Migration[5.2]
  def change
    remove_column :script_subscriber_allowed_performance_audit_tags, :allowed_script_subscriber_id
    add_column :script_subscriber_allowed_performance_audit_tags, :url_pattern, :string
    rename_column :script_subscriber_allowed_performance_audit_tags, :performance_audit_script_subscriber_id, :script_subscriber_id
  end
end

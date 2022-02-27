class RemoveLegacyAuditColumnsAgain < ActiveRecord::Migration[6.1]
  def up
    remove_column :audits, :performance_audit_iterations
    remove_column :tag_preferences, :performance_audit_iterations
    rename_column :performance_audit_configurations, :performance_audit_iterations, :num_performance_audit_iterations
  end
end

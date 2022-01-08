class ChangeAuditErrorMessageToPerformanceAuditErrorMessage < ActiveRecord::Migration[6.1]
  def up
    rename_column :audits, :error_message, :performance_audit_error_message
  end

  def down
    rename_column :audits, :performance_audit_error_message, :error_message
  end
end

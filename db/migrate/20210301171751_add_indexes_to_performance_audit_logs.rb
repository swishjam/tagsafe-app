class AddIndexesToPerformanceAuditLogs < ActiveRecord::Migration[5.2]
  def change
    add_index :performance_audit_logs, :performance_audit_id
  end
end

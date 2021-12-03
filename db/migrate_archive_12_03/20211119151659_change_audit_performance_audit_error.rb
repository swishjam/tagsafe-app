class ChangeAuditPerformanceAuditError < ActiveRecord::Migration[6.1]
  def change
    remove_column :audits, :errored_individual_performance_audit_id
    add_column :audits, :error_message, :string
  end
end

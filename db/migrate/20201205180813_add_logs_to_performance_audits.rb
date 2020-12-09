class AddLogsToPerformanceAudits < ActiveRecord::Migration[5.2]
  def change
    create_table :performance_audit_logs do |t|
      t.integer :performance_audit_id
      t.longtext :logs
    end
  end
end

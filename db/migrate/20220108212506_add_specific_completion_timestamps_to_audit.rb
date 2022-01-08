class AddSpecificCompletionTimestampsToAudit < ActiveRecord::Migration[6.1]
  def up
    remove_column :audits, :completed_at
    remove_column :audits, :enqueued_at

    add_column :audits, :enqueued_suite_at, :timestamp
    add_column :audits, :performance_audit_completed_at, :timestamp
    add_column :audits, :page_change_audit_completed_at, :timestamp
    add_column :audits, :functional_tests_completed_at, :timestamp
  end

  def down
    add_column :audits, :completed_at, :timestamp
    add_column :audits, :enqueued_at, :timestamp

    remove_column :audits, :enqueued_suite_at
    remove_column :audits, :performance_audit_completed_at
    remove_column :audits, :page_change_audit_completed_at
    remove_column :audits, :functional_tests_completed_at
  end
end

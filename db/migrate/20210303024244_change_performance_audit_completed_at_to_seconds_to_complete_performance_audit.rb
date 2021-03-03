class ChangePerformanceAuditCompletedAtToSecondsToCompletePerformanceAudit < ActiveRecord::Migration[5.2]
  def change
    ActiveRecord::Base.transaction do
      add_column :audits, :seconds_to_complete_performance_audit, :float
      completed_audits = Audit.completed
      puts "Updating #{completed_audits.count} audits."
      completed_audits.each do |audit|
        puts "."
        audit.update(seconds_to_complete_performance_audit: (audit.performance_audit_completed_at - audit.performance_audit_enqueued_at)/60.0)
      end
      puts "Updated #{completed_audits.count} audits."
      remove_column :audits, :performance_audit_completed_at
    end
  end
end

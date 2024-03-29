class ChangePerformanceAuditCompletedAtToSecondsToCompletePerformanceAudit < ActiveRecord::Migration[5.2]
  def change
    ActiveRecord::Base.transaction do
      add_column :audits, :seconds_to_complete, :float
      completed_audits = Audit.where.not(performance_audit_completed_at: nil)
      puts "Updating #{completed_audits.count} audits."
      completed_audits.each do |audit|
        puts "."
        audit.update(seconds_to_complete: (audit.performance_audit_completed_at - audit.enqueued_at)/60.0)
      end
      puts "Updated #{completed_audits.count} audits."
      remove_column :audits, :performance_audit_completed_at
    end
  end
end

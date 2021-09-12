class AddErrorsToIndividualPerformanceAuditAndAttemptCountToAudit < ActiveRecord::Migration[6.1]
  def change
    remove_column :audits, :is_baseline
    
    remove_column :audits, :performance_audit_error_message    
    add_reference :audits, :errored_individual_performance_audit
    add_column :performance_audits, :error_message, :string
    
    add_column :audits, :attempt_number, :integer
    
    rename_column :tag_preferences, :performance_audit_iterations, :performance_audit_iterations

    rename_column :audits, :performance_audit_url, :page_url_performance_audit_performed_on
    add_column :tag_preferences, :page_url_to_perform_audit_on, :string
  end
end

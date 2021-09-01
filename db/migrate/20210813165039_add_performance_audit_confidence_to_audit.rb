class AddPerformanceAuditConfidenceToAudit < ActiveRecord::Migration[6.1]
  def change
    add_column :audits, :performance_audit_iterations, :integer
    add_column :performance_audits, :tagsafe_score_standard_deviation, :float
    # add_column :performance_audits, :confidence_score
  end
end

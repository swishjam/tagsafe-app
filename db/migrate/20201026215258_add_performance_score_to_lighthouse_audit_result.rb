class AddPerformanceScoreToLighthouseAuditResult < ActiveRecord::Migration[5.2]
  def change
    add_column :lighthouse_audit_results, :performance_score, :float
  end
end

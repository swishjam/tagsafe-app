class AddUsedForScoringToPerformanceAudit < ActiveRecord::Migration[6.1]
  def change
    add_column :performance_audits, :used_for_scoring, :boolean, default: false
  end
end

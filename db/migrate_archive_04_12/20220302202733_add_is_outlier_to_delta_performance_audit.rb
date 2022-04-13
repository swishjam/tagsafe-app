class AddIsOutlierToDeltaPerformanceAudit < ActiveRecord::Migration[6.1]
  def up
    add_column :delta_performance_audits, :is_outlier, :boolean
  end
end

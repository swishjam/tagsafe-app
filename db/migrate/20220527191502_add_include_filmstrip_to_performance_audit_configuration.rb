class AddIncludeFilmstripToPerformanceAuditConfiguration < ActiveRecord::Migration[6.1]
  def up
    add_column :performance_audit_configurations, :include_filmstrip_frames, :boolean
    add_column :general_configurations, :perf_audit_include_filmstrip_frames, :boolean
  end

  def down
    remove_column :performance_audit_configurations, :include_filmstrip_frames
    remove_column :general_configurations, :perf_audit_include_filmstrip_frames
  end
end

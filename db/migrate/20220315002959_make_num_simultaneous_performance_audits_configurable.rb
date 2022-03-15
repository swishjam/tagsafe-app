class MakeNumSimultaneousPerformanceAuditsConfigurable < ActiveRecord::Migration[6.1]
  def change
    # add_column :default_audit_configurations, :perf_audit_batch_size, :integer
    add_column :performance_audit_configurations, :batch_size, :integer
  end
end

class AddMaxFailedPerformanceAuditsToDefaultAuditConfiguration < ActiveRecord::Migration[6.1]
  def up
    add_column :default_audit_configurations, :perf_audit_max_failures, :integer
    add_column :performance_audit_configurations, :max_failures, :integer
    # remove_column :default_audit_configurations, :minimum_num_performance_audit_sets
    # remove_column :default_audit_configurations, :maximum_num_performance_audit_sets
    # remove_column :default_audit_configurations, :fail_performance_audit_when_confidence_range_not_met
  end

  def down
  end
end

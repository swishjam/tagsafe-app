class AddMaxFailedPerformanceAuditsToDefaultAuditGeneralConfiguration < ActiveRecord::Migration[6.1]
  def up
    # add_column :configurations, :perf_audit_max_failures, :integer
    # add_column :performance_audit_configurations, :max_failures, :integer
    # remove_column :configurations, :minimum_num_performance_audit_sets
    # remove_column :configurations, :maximum_num_performance_audit_sets
    # remove_column :configurations, :fail_performance_audit_when_confidence_range_not_met
  end

  def down
  end
end

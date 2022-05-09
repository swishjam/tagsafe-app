class ChangeUptimeRegionSubscriptionRestrictionToTotalCount < ActiveRecord::Migration[6.1]
  def up
    # remove_column :subscription_feature_restrictions, :uptime_regions_availability
    
    # add_column :subscription_feature_restrictions, :uptime_checks_included_per_month, :integer
    add_column :subscription_feature_restrictions, :release_checks_included_per_month, :integer
    # rename_column :subscription_feature_restrictions, :max_manual_performance_audits_per_month, :manual_performance_audits_included_per_month
    # rename_column :subscription_feature_restrictions, :max_manual_test_runs_per_month, :manual_test_runs_included_per_month
    # rename_column :subscription_feature_restrictions, :max_automated_performance_audits_per_month, :automated_performance_audits_included_per_month
    # rename_column :subscription_feature_restrictions, :max_automated_test_runs_per_month, :automated_test_runs_included_per_month
    # add_column :subscription_feature_restrictions, :package_inherited_from, :string
  end

  def down
  end
end

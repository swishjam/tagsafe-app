class CreateSubscriptionFeatureRestrictions < ActiveRecord::Migration[6.1]
  def up
    create_table :subscription_feature_restrictions do |t|
      t.string :uid, index: true
      t.references :domain
      t.integer :max_manual_performance_audits_per_month
      t.integer :max_manual_test_runs_per_month
      t.integer :max_automated_performance_audits_per_month
      t.integer :max_automated_test_runs_per_month
      t.string :uptime_regions_availability
      t.boolean :has_advance_performance_audit_configurations
      t.integer :min_release_check_minute_interval
      t.integer :tag_sync_minute_cadence
      t.integer :data_retention_days
    end
  end

  def down
    drop_table :subscription_feature_restrictions
  end
end

class AddAdditionalGeneralConfigurationOptions < ActiveRecord::Migration[6.1]
  def up
    add_column :tag_preferences, :release_check_minute_interval, :integer
    add_column :configurations, :perf_audit_minimum_num_sets, :integer
    add_column :configurations, :perf_audit_maximum_num_sets, :integer
    add_column :configurations, :perf_audit_fail_when_confidence_range_not_met, :boolean
    add_column :configurations, :enable_monitoring_on_new_tags, :boolean

    add_column :performance_audit_configurations, :minimum_num_sets, :integer
    add_column :performance_audit_configurations, :maximum_num_sets, :integer
    add_column :performance_audit_configurations, :fail_when_confidence_range_not_met, :boolean
  end
end

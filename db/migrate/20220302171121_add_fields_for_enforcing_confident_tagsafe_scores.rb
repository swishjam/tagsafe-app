class AddFieldsForEnforcingConfidentTagsafeScores < ActiveRecord::Migration[6.1]
  def up
    add_column :audits, :num_performance_audit_sets_ran, :integer
    rename_table :default_audit_configuration, :default_audit_configurations
    
    add_column :default_audit_configurations, :perf_audit_completion_indicator_type, :string
    add_column :default_audit_configurations, :perf_audit_required_tagsafe_score_range, :float
    rename_column :default_audit_configurations, :num_perf_audit_iterations, :num_perf_audits_to_run
    
    add_column :performance_audit_configurations, :completion_indicator_type, :string    
    add_column :performance_audit_configurations, :required_tagsafe_score_range, :float
    rename_column :performance_audit_configurations, :num_performance_audit_iterations, :num_performance_audits_to_run
  end
end

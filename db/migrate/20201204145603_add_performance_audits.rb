class AddPerformanceAudits < ActiveRecord::Migration[5.2]
  def change
    add_column :script_subscribers, :allowed_third_party_tag, :boolean, default: false
    add_column :script_subscribers, :is_third_party_tag, :boolean, default: true

    create_table :performance_audits do |t|
      t.integer :audit_id
      t.string :type
    
      t.timestamps
    end

    create_table :performance_audit_metrics do |t|
      t.integer :performance_audit_id
      t.integer :performance_audit_metric_type_id
      t.float :result
    end

    create_table :performance_audit_metric_types do |t|
      t.string :title
      t.string :key
      t.text :description
      t.string :unit
    end

    rename_column :audits, :lighthouse_audit_enqueued_at, :performance_audit_enqueued_at
    rename_column :audits, :lighthouse_audit_completed_at, :performance_audit_completed_at
    rename_column :audits, :lighthouse_error_message, :performance_audit_error_message
    rename_column :audits, :lighthouse_audit_url, :performance_audit_url

    drop_table :lighthouse_audit_metric_types
    drop_table :lighthouse_audit_metrics
    drop_table :lighthouse_audits

    rename_table :lighthouse_preferences, :performance_audit_preferences
    remove_column :performance_audit_preferences, :should_capture_individual_audit_metrics
    remove_column :performance_audit_preferences, :performance_impact_threshold
  end
end

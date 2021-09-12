class ChangeLighthouseAuditResultsToPolymorphic < ActiveRecord::Migration[5.2]
  def up
    create_table :audits do |t|
      t.integer :tag_version_id
      t.integer :tag_id
      t.integer :execution_reason_id
      t.boolean :primary
      t.string :lighthouse_audit_url
      t.timestamp :lighthouse_audit_enqueued_at
      t.timestamp :lighthouse_audit_completed_at
      t.timestamp :test_suite_enqueued_at
      t.timestamp :test_suite_completed_at
      t.timestamp :created_at, null: false, default: "CURRENT_TIMESTAMP"
    end

    remove_column :lighthouse_audits, :performance_audit_iterations
    remove_column :lighthouse_audits, :enqueued_at
    remove_column :lighthouse_audits, :completed_at
    remove_column :lighthouse_audits, :audited_url
    remove_column :lighthouse_audits, :primary
    remove_column :lighthouse_audits, :tag_version_id
    remove_column :lighthouse_audits, :tag_id
    remove_column :lighthouse_audits, :execution_reason_id
    remove_column :lighthouse_audits, :passed
    add_column :lighthouse_audits, :performance_score, :float
    add_column :lighthouse_audits, :type, :string

    rename_table :lighthouse_audit_result_metrics, :lighthouse_audit_metrics
    rename_table :lighthouse_audit_result_metric_types, :lighthouse_audit_metric_types
    
    add_column :lighthouse_audit_results, :type, :string
    remove_column :lighthouse_audit_results, :lighthouse_audit_result_type_id

    rename_column :lighthouse_audit_metrics, :lighthouse_audit_result_id, :lighthouse_audit_id
    rename_column :lighthouse_audit_metrics, :lighthouse_audit_result_metric_type_id, :lighthouse_audit_metric_type_id

    drop_table :lighthouse_audit_types
    drop_table :lighthouse_audit_results
  end
end

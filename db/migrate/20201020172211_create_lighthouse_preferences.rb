class CreateLighthousePreferences < ActiveRecord::Migration[5.2]
  def change
    remove_column :tags, :run_lighthouse_audit
    add_column :lighthouse_audits, :performance_audit_iterations, :integer

    create_table :lighthouse_preferences do |t|
      t.integer :tag_id
      t.boolean :should_run_audit
      t.string :page_url_to_perform_audit_on
      t.integer :performance_audit_iterations
      t.boolean :should_capture_individual_audit_metrics
    end
  end
end

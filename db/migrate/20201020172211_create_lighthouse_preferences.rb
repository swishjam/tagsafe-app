class CreateLighthousePreferences < ActiveRecord::Migration[5.2]
  def change
    remove_column :script_subscribers, :run_lighthouse_audit
    add_column :lighthouse_audits, :num_test_iterations, :integer

    create_table :lighthouse_preferences do |t|
      t.integer :script_subscriber_id
      t.boolean :should_run_audit
      t.string :url_to_audit
      t.integer :num_test_iterations
      t.boolean :should_capture_individual_audit_metrics
    end
  end
end

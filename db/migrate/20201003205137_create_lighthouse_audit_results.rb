class CreateLighthouseAuditResults < ActiveRecord::Migration[5.2]
  def change
    create_table :lighthouse_audit_results do |t|
      t.integer :lighthouse_audit_id
      t.integer :script_test_type_id
    end

    create_table :lighthouse_audits do |t|
      t.integer :domain_id
      t.integer :script_id
      t.integer :script_change_id
      t.boolean :passed
      t.timestamps
    end

    create_table :lighthouse_audit_result_metrics do |t|
      t.integer :lighthouse_audit_result_id
      t.string :name
      t.integer :result
      t.integer :score
    end
  end
end
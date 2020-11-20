class CreateLighthouseAuditTypes < ActiveRecord::Migration[5.2]
  def change
    create_table :lighthouse_audit_types do |t|
      t.string :name
    end

    remove_column :lighthouse_audit_results, :script_test_type_id
    add_column :lighthouse_audit_results, :lighthouse_audit_type_id, :integer
  end
end

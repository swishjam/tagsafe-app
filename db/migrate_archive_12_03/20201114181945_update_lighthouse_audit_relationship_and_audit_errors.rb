class UpdateLighthouseAuditRelationshipAndAuditErrors < ActiveRecord::Migration[5.2]
  def change
    add_column :lighthouse_audits, :audit_id, :integer
    add_column :audits, :lighthouse_error_message, :string
  end
end

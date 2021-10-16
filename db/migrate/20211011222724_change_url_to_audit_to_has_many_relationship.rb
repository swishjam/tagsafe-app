class ChangeUrlToAuditToHasManyRelationship < ActiveRecord::Migration[6.1]
  def change
    create_table :urls_to_audit do |t|
      t.string :uid
      t.references :tag
      t.string :audit_url
      t.string :display_url
      t.boolean :tagsafe_hosted
      t.boolean :primary
    end

    add_reference :audits, :audited_url

    remove_column :tag_preferences, :page_url_to_perform_audit_on
    remove_column :audits, :page_url_performance_audit_performed_on
  end
end

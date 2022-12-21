class AddErrorMessageToAuditComponents < ActiveRecord::Migration[6.1]
  def change
    add_column :audit_components, :error_message, :string
    add_column :audits, :error_message, :string
    
    add_column :tags, :is_tagsafe_hostable, :boolean
    add_reference :tag_versions, :primary_audit
    add_column :tag_versions, :blocked_from_promoting_to_live, :boolean
  end
end

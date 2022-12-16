class AddErrorMessageToAuditComponents < ActiveRecord::Migration[6.1]
  def change
    add_column :audit_components, :error_message, :string
    add_column :audits, :error_message, :string
    
    add_reference :tag_versions, :audit_blocking_live_promotion
    add_column :tags, :is_tagsafe_hostable, :boolean
  end
end

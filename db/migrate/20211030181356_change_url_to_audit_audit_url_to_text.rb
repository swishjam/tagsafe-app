class ChangeUrlToAuditAuditUrlToText < ActiveRecord::Migration[6.1]
  def change
    change_column :urls_to_audit, :audit_url, :text
  end
end

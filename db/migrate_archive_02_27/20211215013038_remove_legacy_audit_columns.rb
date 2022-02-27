class RemoveLegacyAuditColumns < ActiveRecord::Migration[6.1]
  def change
    remove_column :audits, :attempt_number
    remove_column :audits, :audited_url_id
  end
end

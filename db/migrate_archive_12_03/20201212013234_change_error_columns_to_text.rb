class ChangeErrorColumnsToText < ActiveRecord::Migration[5.2]
  def change
    change_column :audits, :performance_audit_error_message, :text
    #Ex:- change_column("admin_users", "email", :string, :limit =>25)
  end
end

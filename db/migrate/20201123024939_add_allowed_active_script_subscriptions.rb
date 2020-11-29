class AddAllowedActiveScriptSubscriptions < ActiveRecord::Migration[5.2]
  def change
    change_column :audits, :lighthouse_audit_url, :string
    remove_column :audits, :lighthouse_audit_iterations
    add_column :organizations, :maximum_active_script_subscriptions, :integer
  end
end

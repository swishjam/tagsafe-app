class AddShouldRunAuditToScriptSubscriber < ActiveRecord::Migration[5.2]
  def change
    add_column :script_subscribers, :should_run_audit, :boolean
  end
end

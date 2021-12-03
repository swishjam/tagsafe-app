class AddShouldRunAuditToTag < ActiveRecord::Migration[5.2]
  def change
    add_column :tags, :should_run_audit, :boolean
  end
end

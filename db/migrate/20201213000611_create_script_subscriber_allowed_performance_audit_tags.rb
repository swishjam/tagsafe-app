class CreateScriptSubscriberAllowedPerformanceAuditTags < ActiveRecord::Migration[5.2]
  def change
    create_table :script_subscriber_allowed_performance_audit_tags do |t|
      t.integer :performance_audit_script_subscriber_id
      t.integer :allowed_script_subscriber_id
    end
  end
end

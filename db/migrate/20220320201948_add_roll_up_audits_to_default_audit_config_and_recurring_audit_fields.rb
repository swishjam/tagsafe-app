class AddRollUpAuditsToDefaultAuditConfigAndRecurringAuditFields < ActiveRecord::Migration[6.1]
  def up
    add_column :default_audit_configurations, :roll_up_audits_by_tag_version, :boolean
    add_column :tag_preferences, :scheduled_audit_minute_interval, :integer
  end
end

class AddSupportForAuditThrottling < ActiveRecord::Migration[5.2]
  def change
    add_column :script_subscribers, :throttle_minute_threshold, :integer
    add_column :audits, :throttled, :boolean, default: false
  end
end

class AddUidIndexesWhereMissing < ActiveRecord::Migration[6.1]
  def up
    add_index :blocked_resources, :uid
    add_index :events, :uid
    add_index :executed_step_functions, :uid
    add_index :flags, :uid
    add_index :object_flags, :uid
    add_index :page_load_resources, :uid
    add_index :page_load_traces, :uid
    add_index :performance_audit_calculators, :uid
    add_index :tag_check_regions_to_check, :uid
    add_index :urls_to_audit, :uid
    add_index :user_invites, :token

    drop_table :monitored_scripts
    drop_table :filmstrip_screenshots
    drop_table :notification_subscribers
    drop_table :page_load_screenshots
    drop_table :scripts
    drop_table :subscription_options
    drop_table :tag_check_region
    drop_table :test_run_screenshots
    drop_table :urls_to_audits
    drop_table :user_roles
  end
end

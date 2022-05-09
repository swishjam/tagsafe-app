class SeparateTagChecksIntoReleaseAndUptimeChecks < ActiveRecord::Migration[6.1]
  def up
    rename_table :tag_checks, :uptime_checks
    # remove_reference :uptime_checks, :uptime_check_region
    add_reference :uptime_checks, :uptime_region
    remove_column :uptime_checks, :content_has_detectable_changes
    remove_column :uptime_checks, :content_is_the_same_as_a_previous_version
    remove_column :uptime_checks, :bytesize_changed
    remove_column :uptime_checks, :hash_changed
    remove_column :uptime_checks, :captured_new_tag_version

    create_table :release_checks do |t|
      t.string :uid, index: true
      t.references :tag
      t.boolean :content_is_the_same_as_a_previous_version
      t.boolean :bytesize_changed
      t.boolean :hash_changed
      t.boolean :captured_new_tag_version
      t.datetime :executed_at
      t.timestamps
    end

    rename_table :tag_check_regions, :uptime_regions
    rename_table :tag_check_regions_to_check, :uptime_regions_to_check
    remove_reference :uptime_regions_to_check, :uptime_check_region
    add_reference :uptime_regions_to_check, :uptime_region

    remove_reference :tag_versions, :tag_check_captured_with
    add_reference :tag_versions, :release_check_captured_with

    remove_column :tag_preferences, :should_log_tag_checks
    remove_column :tag_preferences, :tag_check_minute_interval
    add_column :tag_preferences, :release_check_minute_interval, :integer

    rename_table :tag_check_schedule_aws_event_bridge_rules, :release_check_schedule_aws_event_bridge_rules
    remove_reference :release_check_schedule_aws_event_bridge_rules, :tag_check_region
    add_reference :release_check_schedule_aws_event_bridge_rules, :uptime_check_region, index: { name: :index_release_check_schedule_aws_event_bridge_rules_on_ucr }
    remove_column :release_check_schedule_aws_event_bridge_rules, :associated_tag_check_minute_interval

    rename_table :release_check_schedule_aws_event_bridge_rules, :aws_event_bridge_rules
    remove_column :aws_event_bridge_rules, :uptime_check_region_id
    add_column :aws_event_bridge_rules, :type, :string
    add_column :aws_event_bridge_rules, :region, :string

    drop_table :organizations
  end
end

class CreateEventBridgeRules < ActiveRecord::Migration[6.1]
  def up
    create_table :uptime_check_schedule_aws_event_bridge_rules do |t|
      t.string :uid, index: true
      t.references :uptime_region, index: { name: :index_tcsaebr_on_uptime_region_id }
      t.string :name
      t.string :associated_release_check_minute_interval
      t.boolean :enabled
    end
  end

  def down
    drop_table :uptime_check_schedule_aws_event_bridge_rules
  end
end

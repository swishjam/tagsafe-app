class CreateEventBridgeRules < ActiveRecord::Migration[6.1]
  def up
    create_table :tag_check_schedule_aws_event_bridge_rules do |t|
      t.string :uid, index: true
      t.references :tag_check_region, index: { name: :index_tcsaebr_on_tag_check_region_id }
      t.string :name
      t.string :associated_tag_check_minute_interval
      t.boolean :enabled
    end
  end

  def down
    drop_table :tag_check_schedule_aws_event_bridge_rules
  end
end

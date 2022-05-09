class AddUptimeRegions < ActiveRecord::Migration[6.1]
  def up
    create_table :uptime_regions do |t|
      t.string :uid, index: true
      t.string :aws_region_name, index: true
      t.string :location
    end
    create_table :uptime_regions_to_check do |t|
      t.string :uid, index: true
      t.references :tag
      t.references :uptime_region
    end
  end

  def down
  end
end

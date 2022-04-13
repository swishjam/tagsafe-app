class AddTagCheckRegions < ActiveRecord::Migration[6.1]
  def up
    create_table :tag_check_regions do |t|
      t.string :uid, index: true
      t.string :aws_region_name, index: true
      t.string :location
    end
    create_table :tag_check_regions_to_check do |t|
      t.string :uid, index: true
      t.references :tag
      t.references :tag_check_region
    end
  end

  def down
  end
end

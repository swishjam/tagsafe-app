class CreateTagImageDomainLookupPatterns < ActiveRecord::Migration[5.2]
  def change
    drop_table :script_domain_images
    add_column :scripts, :tag_image_id, :integer
    
    create_table :tag_image_domain_lookup_patterns do |t|
      t.integer :tag_image_id
      t.string :url_pattern
    end
  end
end

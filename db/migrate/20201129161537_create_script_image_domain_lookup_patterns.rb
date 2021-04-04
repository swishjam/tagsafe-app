class CreateTagImageDomainLookupPatterns < ActiveRecord::Migration[5.2]
  def change
    drop_table :script_domain_images
    add_column :scripts, :script_image_id, :integer
    
    create_table :script_image_domain_lookup_patterns do |t|
      t.integer :script_image_id
      t.string :url_pattern
    end
  end
end

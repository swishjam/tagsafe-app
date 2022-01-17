class AddTagMappingDataTables < ActiveRecord::Migration[6.1]
  def up
    create_table :tag_identifying_data do |t|
      t.string :uid, index: true
      t.string :name
      t.string :company
      t.string :homepage
      t.string :category
    end

    create_table :tag_identifying_data_domains do |t|
      t.string :uid, index: true
      t.references :tag_identifying_data
      t.string :url_pattern, index: true
    end
    drop_table :tag_images
    drop_table :tag_image_domain_lookup_patterns
    add_reference :tags, :tag_identifying_data
  end

  def down
    drop_table :tag_identifying_data
    drop_table :tag_identifying_data_domains
    remove_reference :tags, :tag_identifying_data
  end
end

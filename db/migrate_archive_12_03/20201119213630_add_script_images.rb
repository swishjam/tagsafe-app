class AddTagImages < ActiveRecord::Migration[5.2]
  def change
    create_table :script_domain_images do |t|
      t.integer :tag_image_id
      t.string :script_domain_url
    end

    create_table :tag_images do |t|
      t.timestamps
    end
  end
end

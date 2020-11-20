class AddScriptImages < ActiveRecord::Migration[5.2]
  def change
    create_table :script_domain_images do |t|
      t.integer :script_image_id
      t.string :script_domain_url
    end

    create_table :script_images do |t|
      t.timestamps
    end
  end
end

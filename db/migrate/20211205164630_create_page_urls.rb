class CreatePageUrls < ActiveRecord::Migration[6.1]
  def change
    create_table :page_urls do |t|
      t.string :uid
      t.references :domain
      t.string :full_url
      t.string :hostname
      t.string :pathname
      t.timestamps
    end

    add_index :page_urls, :uid
    add_index :page_urls, :full_url
    add_index :page_urls, :hostname
    add_index :page_urls, :pathname
  end
end

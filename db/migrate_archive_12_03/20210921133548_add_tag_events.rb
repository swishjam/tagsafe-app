class AddTagEvents < ActiveRecord::Migration[6.1]
  def change
    create_table :tag_events do |t|
      t.string :uid
      t.references :tag
      t.references :url_crawl
      t.string :uid
      t.string :type, null: false
      t.datetime :created_at, null: false
      t.text :metadata
    end
  end
end

class CreatePageUrlsTagFoundOn < ActiveRecord::Migration[6.1]
  def change
    create_table :page_urls_tag_found_on do |t|
      t.string :uid, index: true
      t.references :tag
      t.references :page_url
      t.timestamp :last_seen_at
      t.timestamps
    end
  end
end

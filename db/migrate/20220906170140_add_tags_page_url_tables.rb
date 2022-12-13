class AddTagsPageUrlTables < ActiveRecord::Migration[6.1]
  def change
    create_table :tag_inject_page_url_rules do |t|
      t.string :uid, index: true
      t.string :type
      t.string :url
      t.boolean :is_regex_pattern
    end
  end
end

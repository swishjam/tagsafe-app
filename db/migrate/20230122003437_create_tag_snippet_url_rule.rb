class CreateTagSnippetUrlRule < ActiveRecord::Migration[6.1]
  def change
    create_table :tag_snippet_injection_url_rules do |t|
      t.string :uid, index: true
      t.references :tag_snippet
      t.string :type
      t.string :url
      t.timestamps
    end
  end
end

class AddFingerPrintToTagSnippet < ActiveRecord::Migration[6.1]
  def change
    add_column :tag_snippets, :content_fingerprint, :string
  end
end

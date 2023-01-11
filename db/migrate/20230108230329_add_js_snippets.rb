class AddJsSnippets < ActiveRecord::Migration[6.1]
  def change
    create_table :tag_snippets do |t|
      t.string :uid, index: true
      t.references :container
      t.string :name
      t.string :state
      t.string :event_to_inject_snippet_on
    end

    add_reference :tags, :tag_snippet
  end
end

class AddDraftFlagToTag < ActiveRecord::Migration[6.1]
  def up
    add_column :tags, :is_draft, :boolean
  end

  def down
    remove_column :tags, :is_draft
  end
end

class MoveConfigsToTagsTable < ActiveRecord::Migration[6.1]
  def change
    add_column :tags, :is_tagsafe_hosted, :boolean
  end
end

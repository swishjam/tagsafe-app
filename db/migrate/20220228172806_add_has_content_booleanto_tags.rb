class AddHasContentBooleantoTags < ActiveRecord::Migration[6.1]
  def up
    add_column :tags, :has_content, :boolean
  end
end

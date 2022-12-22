class AddNameToTag < ActiveRecord::Migration[6.1]
  def change
    add_column :tags, :name, :string
    add_column :tag_versions, :sha_512, :string
  end
end

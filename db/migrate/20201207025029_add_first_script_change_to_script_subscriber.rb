class AddFirstTagVersionToTag < ActiveRecord::Migration[5.2]
  def change
    add_column :tags, :first_tag_version_id, :integer
  end
end

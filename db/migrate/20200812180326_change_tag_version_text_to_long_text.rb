class ChangeTagVersionTextToLongText < ActiveRecord::Migration[5.2]
  def change
    change_column :tag_versions, :content, :mediumtext
  end
end

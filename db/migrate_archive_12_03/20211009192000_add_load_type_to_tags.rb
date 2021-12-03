class AddLoadTypeToTags < ActiveRecord::Migration[6.1]
  def change
    add_column :tags, :load_type, :string
  end
end

class AddConfiguredLoadTypeToTags < ActiveRecord::Migration[6.1]
  def change
    add_column :tags, :configured_load_type, :string
  end
end

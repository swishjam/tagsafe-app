class AddFriendlyNameToTag < ActiveRecord::Migration[5.2]
  def change
    add_column :tags, :friendly_name, :string
  end
end

class AddDeferByDefaultToContainers < ActiveRecord::Migration[6.1]
  def change
    add_column :containers, :defer_script_tags_by_default, :boolean
  end
end

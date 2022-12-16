class AddTagsafeJsEnabledToContainers < ActiveRecord::Migration[6.1]
  def change
    add_column :containers, :tagsafe_js_enabled, :boolean
  end
end

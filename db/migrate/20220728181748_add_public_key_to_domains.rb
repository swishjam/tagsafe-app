class AddPublicKeyToDomains < ActiveRecord::Migration[6.1]
  def up
    add_column :domains, :instrumentation_key, :string, index: true
    add_column :tags, :is_tagsafe_hosted, :boolean
  end

  def down
    remove_column :domains, :instrumentation_key
    remove_column :tags, :is_tagsafe_hosted
  end
end

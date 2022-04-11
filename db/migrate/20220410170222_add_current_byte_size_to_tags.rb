class AddCurrentByteSizeToTags < ActiveRecord::Migration[6.1]
  def up
    add_column :tags, :last_captured_byte_size, :integer
  end
end

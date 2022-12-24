class AddOriginalByteSizeAndTagsafeMinifiedByteSizeToTagVersions < ActiveRecord::Migration[6.1]
  def change
    add_column :tag_versions, :original_content_byte_size, :integer
    add_column :tag_versions, :tagsafe_minified_byte_size, :integer
  end
end

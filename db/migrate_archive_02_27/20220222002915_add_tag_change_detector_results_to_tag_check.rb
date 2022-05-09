class AddTagChangeDetectorResultsToReleaseCheck < ActiveRecord::Migration[6.1]
  def up
    add_column :tag_checks, :content_has_detectable_changes, :boolean
    add_column :tag_checks, :content_is_the_same_as_a_previous_version, :boolean
    add_column :tag_checks, :bytesize_changed, :boolean
    add_column :tag_checks, :hash_changed, :boolean
  end

  def down
    remove_column :tag_checks, :content_has_detectable_changes
    remove_column :tag_checks, :content_is_the_same_as_a_previous_version
    remove_column :tag_checks, :bytesize_changed
    remove_column :tag_checks, :hash_changed
  end
end

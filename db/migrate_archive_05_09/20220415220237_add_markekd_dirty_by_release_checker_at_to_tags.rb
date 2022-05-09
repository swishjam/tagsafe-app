class AddMarkekdDirtyByReleaseCheckerAtToTags < ActiveRecord::Migration[6.1]
  def up
    add_column :tags, :marked_as_pending_tag_version_capture_at, :datetime
  end

  def down
    remove_column :tags, :marked_dirty_by_release_checker_at
  end
end

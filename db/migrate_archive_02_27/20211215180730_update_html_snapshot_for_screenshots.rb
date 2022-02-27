class UpdateHtmlSnapshotForScreenshots < ActiveRecord::Migration[6.1]
  def up
    rename_column :html_snapshots, :s3_file_location, :html_s3_location
    add_column :html_snapshots, :screenshot_s3_location, :string
  end

  def down
    rename_column :html_snapshots, :html_s3_location, :s3_file_location
    remove_column :html_snapshots, :screenshot_s3_location
  end
end

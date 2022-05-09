class AddCapturedNewTagVersionToReleaseCheck < ActiveRecord::Migration[6.1]
  def up
    add_column :tag_checks, :captured_new_tag_version, :boolean
  end
end

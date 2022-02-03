class AddTagCheckReferenceToTagVersion < ActiveRecord::Migration[6.1]
  def up
    add_reference :tag_versions, :tag_check_captured_with
  end

  def down
    remove_column :tag_veresions, :tag_check_captured_with_id
  end
end

class ChangeJsScriptToAttachmentAndAddHasPendingChangesFlag < ActiveRecord::Migration[6.1]
  def up
    # add_column :tags, :has_staged_changes, :boolean
    remove_column :tags, :js_script
  end
end

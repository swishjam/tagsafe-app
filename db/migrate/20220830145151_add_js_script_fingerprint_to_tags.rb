class AddJsScriptFingerprintToTags < ActiveRecord::Migration[6.1]
  def up
    add_column :tags, :js_script_fingerprint, :string
  end

  def down
    remove_column :tags, :js_script_fingerprint
  end
end

class AddUidToPageLoadScreenshots < ActiveRecord::Migration[6.1]
  def change
    add_column :page_load_screenshots, :uid, :string
    add_index :page_load_screenshots, :uid
  end
end

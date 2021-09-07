class AddUrlToDomainScans < ActiveRecord::Migration[6.1]
  def change
    add_column :url_crawls, :url, :string
  end
end

class AddByteCountsToUrlCrawls < ActiveRecord::Migration[6.1]
  def up
    add_column :url_crawls, :num_first_party_bytes, :integer
    add_column :url_crawls, :num_third_party_bytes, :integer
  end

  def down
    remove_column :url_crawls, :num_first_party_bytes
    remove_column :url_crawls, :num_third_party_bytes
  end
end

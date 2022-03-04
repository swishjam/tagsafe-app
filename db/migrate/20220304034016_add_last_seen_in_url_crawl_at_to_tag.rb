class AddLastSeenInUrlCrawlAtToTag < ActiveRecord::Migration[6.1]
  def up
    add_column :tags, :last_seen_in_url_crawl_at, :timestamp
  end
end

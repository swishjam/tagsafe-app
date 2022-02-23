class CreateUrlCrawlRetrievedUrls < ActiveRecord::Migration[6.1]
  def change
    create_table :url_crawl_retrieved_urls do |t|
      t.string :uid, index: true
      t.references :url_crawl
      t.text :url
    end
  end
end

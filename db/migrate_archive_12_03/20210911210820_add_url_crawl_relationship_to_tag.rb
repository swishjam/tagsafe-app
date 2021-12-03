class AddUrlCrawlRelationshipToTag < ActiveRecord::Migration[6.1]
  def change
    add_reference :tags, :url_crawl
  end
end

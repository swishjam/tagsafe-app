class ChangeDomainScansToUrlCrawls < ActiveRecord::Migration[6.1]
  def change
    rename_table :urls_to_scans, :urls_to_crawl
    rename_table :url_crawls, :url_crawls
  end
end

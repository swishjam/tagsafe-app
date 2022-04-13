class AddUrlCrawlReferenceToDomainAudit < ActiveRecord::Migration[6.1]
  def up
    add_reference :domain_audits, :url_crawl
  end
end

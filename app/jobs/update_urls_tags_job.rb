class UpdateUrlsTagsJob < ApplicationJob
  @queue = :default
  
  def perform(domain:, tag_urls:, url_crawl:, initial_scan:)
    TagManager::EvaluateDomainTags.new(
      domain: domain,
      url_scanned: url_crawl.url,
      tag_urls: tag_urls, 
      initial_scan: initial_scan
    ).evaluate!
    url_crawl.completed!
  end
end
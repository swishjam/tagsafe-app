class UrlCrawlCompletedJob < ApplicationJob
  @queue = :default
  
  def perform(tag_urls:, url_crawl:, initial_crawl:)
    TagManager::EvaluateUrlCrawlFoundTags.new(
      url_crawl: url_crawl,
      tag_urls: tag_urls, 
      initial_crawl: initial_crawl
    ).evaluate!
  end
end
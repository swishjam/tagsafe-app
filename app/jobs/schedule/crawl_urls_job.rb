module Schedule
  class CrawlUrlsJob < ApplicationJob
    def perform
      UrlToCrawl.should_crawl.each(&:crawl!)
      # Domain.all.each{ |domain| domain.crawl_and_capture_domains_tags }
    end
  end
end
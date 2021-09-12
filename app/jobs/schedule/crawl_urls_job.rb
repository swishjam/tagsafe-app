module Schedule
  class CrawlUrlsJob < ApplicationJob
    def perform
      UrlToCrawl.should_crawl.each(&:crawl!)
    end
  end
end
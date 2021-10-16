module Schedule
  class CrawlUrlsJob < ApplicationJob
    def perform
      UrlToCrawl.should_crawl.each(&:crawl_now)
    end
  end
end
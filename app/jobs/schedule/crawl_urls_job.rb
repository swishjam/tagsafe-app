module Schedule
  class CrawlUrlsJob < ApplicationJob
    def perform
      PageUrl.should_scan_for_tags.each(&:crawl_for_tags!)
    end
  end
end
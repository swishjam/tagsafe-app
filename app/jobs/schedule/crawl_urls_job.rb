module Schedule
  class CrawlUrlsJob < ApplicationJob
    # queue_as :crawl_url_for_tags_queue
    
    def perform
      PageUrl.should_scan_for_tags.each(&:crawl_now)
      # UrlToCrawl.should_crawl.each(&:crawl_now)
    end
  end
end
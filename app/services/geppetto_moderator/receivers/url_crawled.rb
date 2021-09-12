module GeppettoModerator
  module Receivers
    class UrlCrawled
      def initialize(tag_urls:, url_crawl_id:, error_message:, initial_crawl:)
        @tag_urls = tag_urls
        @url_crawl_id = url_crawl_id
        @error_message = error_message
        @initial_crawl = initial_crawl
      end
    
      def receive!
        if @error_message
          url_crawl.errored!(@error_message)
        else
          UrlCrawlCompletedJob.perform_later(
            tag_urls: @tag_urls, 
            url_crawl: url_crawl, 
            initial_crawl: @initial_crawl
          )
        end
      end
    
      def url_crawl
        @url_crawl ||= UrlCrawl.find(@url_crawl_id)
      end
    end
  end
end
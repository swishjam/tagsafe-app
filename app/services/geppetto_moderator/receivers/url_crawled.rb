module GeppettoModerator
  module Receivers
    class UrlCrawled
      def initialize(tag_urls:, domain_id:, url_crawl_id:, error_message:, initial_scan:)
        @tag_urls = tag_urls
        @domain_id = domain_id
        @url_crawl_id = url_crawl_id
        @error_message = error_message
        @initial_scan = initial_scan
      end
    
      def receive!
        if @error_message
          url_crawl.errored!(@error_message)
        else
          UpdateUrlsTagsJob.perform_later(
            domain: domain, 
            tag_urls: @tag_urls, 
            url_crawl: url_crawl, 
            initial_scan: @initial_scan
          )
        end
      end
    
      def domain
        @domain ||= Domain.find(@domain_id)
      end
    
      def url_crawl
        @url_crawl ||= UrlCrawl.find(@url_crawl_id)
      end
    end
  end
end
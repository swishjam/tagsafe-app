module GeppettoModerator
  module LambdaSenders
    class UrlCrawler < Base
      lambda_service 'url-crawler'
      lambda_function 'crawl'

      def initialize(url_to_crawl, initial_scan: false)
        @url_to_crawl = url_to_crawl
        @initial_scan = initial_scan
      end
    
      private

      def request_payload
        {
          domain_id: @url_to_crawl.domain_id,
          url: @url_to_crawl.url,
          url_crawl_id: url_crawl.id,
          initial_scan: @initial_scan
        }
      end

      def url_crawl
        @url_crawl ||= UrlCrawl.create(domain_id: @url_to_crawl.domain_id, url: @url_to_crawl.url, scan_enqueued_at: Time.now)
      end

      def required_payload_arguments
        %i[domain_id url url_crawl_id initial_scan]
      end
    end
  end
end
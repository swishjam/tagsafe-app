module GeppettoModerator
  module LambdaSenders
    class UrlCrawler < Base
      lambda_service 'url-crawler'
      lambda_function 'crawl'

      def initialize(url_to_crawl, initial_crawl: false)
        @url_to_crawl = url_to_crawl
        @initial_crawl = initial_crawl
      end
    
      private

      def request_payload
        {
          url: url_crawl.url,
          url_crawl_id: url_crawl.id,
          initial_crawl: @initial_crawl
        }
      end

      def url_crawl
        @url_crawl ||= UrlCrawl.create!(domain_id: @url_to_crawl.domain_id, url: @url_to_crawl.url, enqueued_at: Time.now)
      end

      def required_payload_arguments
        %i[url url_crawl_id initial_crawl]
      end
    end
  end
end
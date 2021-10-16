module LambdaModerator
  module Receivers
    class UrlCrawlCompleted
      def initialize(tag_urls:, url_crawl_id:, error_message:, initial_crawl:)
        @tag_urls = tag_urls
        @url_crawl_id = url_crawl_id
        @error_message = error_message
        @initial_crawl = initial_crawl
      end
    
      def evaluate_results!
        if @error_message
          url_crawl.errored!(@error_message)
        else
          TagManager::EvaluateUrlCrawlFoundTags.new(
            url_crawl: url_crawl,
            tag_urls: @tag_urls, 
            initial_crawl: @initial_crawl
          ).evaluate!
        end
      end
    
      def url_crawl
        @url_crawl ||= UrlCrawl.find(@url_crawl_id)
      end

      def add_aws_attributes_to_url_crawl
      end
    end
  end
end
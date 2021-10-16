module LambdaModerator
  module Receivers
    class UrlCrawlCompleted
      def initialize(
        tag_urls:, 
        url_crawl_id:, 
        error_message:, 
        initial_crawl:, 
        aws_log_stream_name:, 
        aws_request_id:, 
        aws_trace_id:
      )
        @tag_urls = tag_urls
        @url_crawl_id = url_crawl_id
        @error_message = error_message
        @initial_crawl = initial_crawl
        @aws_log_stream_name = aws_log_stream_name
        @aws_request_id = aws_request_id
        @aws_trace_id = aws_trace_id
      end
    
      def evaluate_results!
        if @error_message
          url_crawl.errored!(@error_message)
        else
          add_aws_attributes_to_url_crawl
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
        url_crawl.update!(aws_log_stream_name: @aws_log_stream_name, aws_request_id: @aws_request_id, aws_trace_id: @aws_trace_id)
      end
    end
  end
end
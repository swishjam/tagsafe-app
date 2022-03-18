module LambdaFunctionInvoker
  class UrlCrawler < Base
    lambda_service 'url-crawler'
    lambda_function 'find-third-party-tags'

    attr_accessor :url_crawl

    def initialize(url_crawl, attempt_number: 1)
      @url_crawl = url_crawl
      @executed_lambda_function_parent = url_crawl
      @attempt_number = attempt_number
    end
  
    private

    def on_lambda_failure(_error_message)
      url_crawl.errored!("An unexpected error occurred.")
      unless @attempt_number >= 3
        self.class.new(
          UrlCrawl.create!(enqueued_at: Time.now, domain: url_crawl.domain, page_url: url_crawl.page_url), 
          attempt_number: @attempt_number + 1
        ).send!
      end
    end

    def request_payload
      { 
        url_crawl_id: url_crawl.id,
        url: url_crawl.page_url.full_url 
      }
    end

    def required_payload_arguments
      %i[url]
    end
  end
end
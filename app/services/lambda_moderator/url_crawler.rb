module LambdaModerator
  class UrlCrawler < Base
    lambda_service 'url-crawler'
    lambda_function 'crawl'

    attr_accessor :url_crawl

    def initialize(url_crawl)
      @url_crawl = url_crawl
      @executed_lambda_function_parent = url_crawl
      set_enqueued_timestamp
    end
  
    private

    def set_enqueued_timestamp
      url_crawl.update!(enqueued_at: Time.now)
    end

    def request_payload
      { url: url_crawl.page_url.full_url }
    end

    def required_payload_arguments
      %i[url]
    end
  end
end
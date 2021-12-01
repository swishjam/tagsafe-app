module LambdaModerator
  class UrlCrawler < Base
    lambda_service 'url-crawler'
    lambda_function 'crawl'

    attr_accessor :url_crawl

    def initialize(url_crawl, initial_crawl: false)
      @url_crawl = url_crawl
      @initial_crawl = initial_crawl
      @executed_lambda_function_parent = url_crawl
      set_enqueued_timestamp
    end

    # def url_crawl
    #   @url_crawl ||= UrlCrawl.create!(domain_id: @url_to_crawl.domain_id, url: @url_to_crawl.url, enqueued_at: Time.now)
    # end
  
    private

    def set_enqueued_timestamp
      url_crawl.update!(enqueued_at: Time.now)
    end

    def request_payload
      {
        url: url_crawl.url,
        url_crawl_id: url_crawl.id,
        initial_crawl: @initial_crawl
      }
    end

    def required_payload_arguments
      %i[url url_crawl_id initial_crawl]
    end
  end
end
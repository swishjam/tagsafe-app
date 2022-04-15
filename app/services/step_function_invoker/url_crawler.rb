module StepFunctionInvoker
  class UrlCrawler < Base
    self.step_function_arn = "arn:aws:states:us-east-1:407342930315:stateMachine:#{Rails.env}-crawl-url-for-third-party-tags"
    self.results_consumer_klass = StepFunctionResponses::UrlCrawlResult

    attr_accessor :url_crawl

    def initialize(url_crawl)
      @url_crawl = url_crawl
      @receiver_job_queue = url_crawl.is_for_domain_audit? ? TagsafeQueue.CRITICAL : nil
    end

    def executed_step_function_parent
      url_crawl
    end
  
    private

    def request_payload
      { 
        url_crawl_id: url_crawl.id,
        url: url_crawl.page_url.full_url,
        first_party_url_patterns: [url_crawl.page_url.hostname, url_crawl.domain.url_hostname]
      }
    end
  end
end
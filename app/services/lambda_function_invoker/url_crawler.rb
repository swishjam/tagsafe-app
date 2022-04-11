module LambdaFunctionInvoker
  class UrlCrawler < Base
    lambda_service 'url-crawler'
    lambda_function 'find-third-party-tags'
    consumer_klass LambdaEventResponses::UrlCrawlResult

    attr_accessor :url_crawl

    def initialize(url_crawl)
      @url_crawl = url_crawl
      @receiver_job_queue = url_crawl.is_for_domain_audit? ? TagsafeQueue.CRITICAL : TagsafeQueue.NORMAL
    end

    def executed_lambda_function_parent; url_crawl; end
  
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
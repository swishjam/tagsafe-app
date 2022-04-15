class CrawlUrlJob < ApplicationJob
  queue_as { arguments.first.is_for_domain_audit? ? TagsafeQueue.CRITICAL : TagsafeQueue.NORMAL }
  
  def perform(url_crawl)
    StepFunctionInvoker::UrlCrawler.new(url_crawl).send!
  end
end
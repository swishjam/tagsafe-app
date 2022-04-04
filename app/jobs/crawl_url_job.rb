class CrawlUrlJob < ApplicationJob
  queue_as TagsafeQueue.NORMAL
  
  def perform(url_crawl)
    LambdaFunctionInvoker::UrlCrawler.new(url_crawl).send!
  end
end
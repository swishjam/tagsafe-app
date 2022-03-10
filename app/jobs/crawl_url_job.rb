class CrawlUrlJob < ApplicationJob
  def perform(url_crawl)
    LambdaFunctionInvoker::UrlCrawler.new(url_crawl).send!
  end
end
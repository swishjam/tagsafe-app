class CrawlUrlJob < ApplicationJob
  queue_as :crawl_url_for_tags_queue

  def perform(url_to_crawl, initial_crawl: false)
    sender = LambdaModerator::UrlCrawler.new(url_to_crawl, initial_crawl: initial_crawl)
    response = sender.send!
    if response.successful
      capture_successful_crawl(response.response_body)
    else
      sender.url_crawl.errored!(response.error)
    end
  end

  def capture_successful_crawl(response_data)
    if response_data['error_message'] || response_data['errorMessage']
      url_crawl.errored!(response_data['error_message'] || response_data['errorMessage'])
    else
      TagManager::EvaluateUrlCrawlFoundTags.new(
        url_crawl: UrlCrawl.find(response_data['url_crawl_id']),
        tag_urls: response_data['tag_urls'], 
        initial_crawl: response_data['initial_crawl']
      ).evaluate!
    end
  end
end
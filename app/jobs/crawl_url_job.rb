class CrawlUrlJob < ApplicationJob
  # queue_as :crawl_url_for_tags_queue

  def perform(url_crawl)
    sender = LambdaModerator::UrlCrawler.new(url_crawl)
    response = sender.send!
    if response.successful
      capture_successful_crawl(sender.url_crawl, response.response_body)
    else
      sender.url_crawl.errored!(response.error)
    end
  end

  def capture_successful_crawl(url_crawl, response_data)
    if response_data['error'] || response_data['error_message'] || response_data['errorMessage']
      url_crawl.errored!(response_data['error'] || response_data['error_message'] || response_data['errorMessage'])
    else
      url_crawl.update!(num_first_party_bytes: response_data['first_party_bytes'], num_third_party_bytes: response_data['third_party_bytes'])
      TagManager::EvaluateUrlCrawlFoundTags.new(url_crawl: url_crawl, tag_urls: response_data['tag_urls']).evaluate!
    end
  end
end
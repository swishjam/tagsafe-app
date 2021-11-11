class CrawlUrlJob < ApplicationJob
  queue_as :crawl_url_for_tags_queue

  def perform(url_to_crawl, initial_crawl: false)
    sender = LambdaModerator::Senders::UrlCrawler.new(url_to_crawl, initial_crawl: initial_crawl)
    response = sender.send!
    if response.successful
      capture_successful_crawl(response.response_body)
    else
      sender.url_crawl.errored!(response.error)
    end
  end

  def capture_successful_crawl(response_data)
    LambdaModerator::Receivers::UrlCrawlCompleted.new(
      tag_urls: response_data['tag_urls'],
      url_crawl_id: response_data['url_crawl_id'],
      error_message: response_data['error_message'],
      initial_crawl: response_data['initial_crawl'],
      aws_log_stream_name: response_data['aws_log_stream_name'],
      aws_request_id: response_data['aws_request_id'],
      aws_trace_id: response_data['aws_trace_id']
    ).evaluate_results!
  end
end
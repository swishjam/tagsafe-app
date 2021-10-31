class CrawlUrlJob < ApplicationJob
  def perform(url_to_crawl, initial_crawl: false)
    sender = LambdaModerator::Senders::UrlCrawler.new(url_to_crawl, initial_crawl: initial_crawl)
    response = sender.send!
    response_data = JSON.parse(response.payload.read)
    puts "CrawlUrlJob resulted in #{response_data}"
    if response.status_code == 200 && response_data['errorMessage'].nil?
      SuccessfulLambdaFunctionReceiverJob.perform_now(response_data)
    else
      sender.url_crawl.errored!(response_data['errorMessage'] || response_data['error'])
    end
  end
end
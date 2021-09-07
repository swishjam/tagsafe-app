module Api
  class UrlCrawlsController < BaseController
    def show
      url_crawl = UrlCrawl.find(params[:id])
      render json: {
        error_message: url_crawl.error_message,
        completed: url_crawl.completed?,
        successful: url_crawl.successful?
      }
    end
  end
end
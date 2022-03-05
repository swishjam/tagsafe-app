class UrlCrawlsController < LoggedInController
  def index
    @url_crawls = current_domain.url_crawls
                                  .most_recent_first(timestamp_column: :enqueued_at)
                                  .includes(:found_tags)
                                  .page(params[:page] || 1).per(params[:per_page || 10])
  end

  def show
    @url_crawl = current_domain.url_crawls.find(params[:id])
    render_breadcrumbs(
      { text: 'URL Crawls', url: url_crawls_path },
      { text: 'URL Crawl', active: true }
    )
  end

  def executed_lambda_function
    @url_crawl = current_domain.url_crawls.find(params[:id])
    @executed_lambda_function = @url_crawl.executed_lambda_function
  end
end
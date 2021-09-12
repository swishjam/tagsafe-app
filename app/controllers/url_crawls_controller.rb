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
      { text: 'URL Crawls', url: domain_url_crawls_path(current_domain) },
      { text: 'URL Crawl', active: true }
    )
  end
end
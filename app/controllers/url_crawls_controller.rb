class UrlCrawlsController < LoggedInController
  def index
    @url_crawls = current_domain.url_crawls
                                  .most_recent_first(timestamp_column: :enqueued_at)
                                  .includes(:found_tags)
                                  .page(params[:page] || 1).per(params[:per_page] || 20)
    render_breadcrumbs(
      { text: 'Settings', url: settings_path },
      { text: 'Tag Syncs', active: true }
    )
  end

  def show
    @url_crawl = current_domain.url_crawls.find(params[:id])
    render_breadcrumbs(
      { text: 'Settings', url: settings_path },
      { text: 'Tag Syncs', url: url_crawls_path },
      { text: "#{@url_crawl.enqueued_at.formatted_short} Tag Sync"}
    )
  end

  def create
    current_domain.crawl_and_capture_domains_tags
    respond_with_notification(message: "Syncing #{current_domain.url}'s third party tags...")
    # current_user.broadcast_notification(message: "Syncing #{current_domain.url}'s third party tags...")
    # head :no_content
  end
end
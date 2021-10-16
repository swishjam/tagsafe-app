class UrlsToCrawlController < LoggedInController
  def create
    url_to_crawl = current_domain.urls_to_crawl.new(url_to_crawl_params)
    if url_to_crawl.save
      current_user.broadcast_notification("#{url_to_crawl.url} added to scan list.")
    else
      current_user.broadcast_notification("Unable to add #{url_to_crawl.url} to scan list. #{url_to_crawl.errors.full_messages.join(' ')}")
    end
    render turbo_stream: turbo_stream.replace(
      "#{current_domain.id}_urls_to_crawl",
      partial: 'urls_to_crawl/index',
      locals: { domain: current_domain }
    )
  end

  def destroy
    url_to_crawl = UrlToCrawl.find(params[:id])
    url_to_crawl.destroy
    current_user.broadcast_notification("#{url_to_crawl.url} removed from scan list.")
    render turbo_stream: turbo_stream.replace(
      "#{current_domain.id}_urls_to_crawl",
      partial: 'urls_to_crawl/index',
      locals: { domain: current_domain }
    )
  end

  private

  def url_to_crawl_params
    params.require(:url_to_crawl).permit(:url)
  end
end
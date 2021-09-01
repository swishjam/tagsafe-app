class UrlsToScansController < LoggedInController
  def create
    url_to_scan = current_domain.urls_to_scans.new(url_to_scan_params)
    if url_to_scan.save
      current_user.broadcast_notification("#{url_to_scan.url} added to scan list.")
    else
      current_user.broadcast_notification("Unable to add #{url_to_scan.url} to scan list. #{url_to_scan.errors.full_messages.join(' ')}")
    end
    render turbo_stream: turbo_stream.replace(
      "#{current_domain.id}_urls_to_scan",
      partial: 'urls_to_scans/index',
      locals: { domain: current_domain }
    )
  end

  def destroy
    url_to_scan = UrlsToScan.find(params[:id])
    url_to_scan.destroy
    current_user.broadcast_notification("#{url_to_scan.url} removed from scan list.")
    render turbo_stream: turbo_stream.replace(
      "#{current_domain.id}_urls_to_scan",
      partial: 'urls_to_scans/index',
      locals: { domain: current_domain }
    )
  end

  private

  def url_to_scan_params
    params.require(:urls_to_scan).permit(:url)
  end
end
class HtmlSnapshotsController < LoggedInController
  def screenshot
    tag = current_domain.tags.find(params[:tag_id])
    html_snapshot = HtmlSnapshot.find(params[:id])
    send_data html_snapshot.fetch_screenshot, :type => 'image/png',:disposition => 'inline'
  end
end
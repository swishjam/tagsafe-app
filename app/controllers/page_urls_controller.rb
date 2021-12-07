class PageUrlsController < LoggedInController
  def create_or_update
    existing_url = current_domain.page_urls.find_by(full_url: params[:full_url])
    if existing_url
      if existing_url.update(should_scan_for_tags: params[:should_scan_for_tags])
        current_user.broadcast_notification("Added #{existing_url.full_url} to sync third party tags from.")
        render turbo_stream: turbo_stream.replace(
          "domain_#{current_domain.uid}_page_urls_to_scan",
          partial: 'page_urls/index',
          locals: { domain: current_domain, page_urls: current_domain.page_urls.should_scan_for_tags, should_scan_for_tags: true }
        )
      else
        render turbo_stream: turbo_stream.replace(
          "domain_#{current_domain.uid}_page_urls_to_scan",
          partial: 'page_urls/index',
          locals: { domain: current_domain, page_urls: current_domain.page_urls.should_scan_for_tags, should_scan_for_tags: true, errors: existing_url.errors.full_messages }
        )
      end
    else
      new_page_url = current_domain.add_url(params[:full_url], should_scan_for_tags: params[:should_scan_for_tags])
      if new_page_url.valid?
        current_user.broadcast_notification("Added #{new_page_url.full_url} to sync third party tags from.")
        render turbo_stream: turbo_stream.replace(
          "domain_#{current_domain.uid}_page_urls_to_scan",
          partial: 'page_urls/index',
          locals: { domain: current_domain, page_urls: current_domain.page_urls.should_scan_for_tags, should_scan_for_tags: true }
        )
      else
        render turbo_stream: turbo_stream.replace(
          "domain_#{current_domain.uid}_page_urls_to_scan",
          partial: 'page_urls/index',
          locals: { domain: current_domain, page_urls: current_domain.page_urls.should_scan_for_tags, should_scan_for_tags: true, errors: new_page_url.errors.full_messages }
        )
      end
    end
  end
end
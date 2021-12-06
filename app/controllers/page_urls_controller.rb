class PageUrlsController < LoggedInController
  def create_or_update_to_run_audits_on
    existing_url = current_domain.page_urls.find_by(full_url: params[:url])
    if existing_url
      existing_url.update!(should_run_audits_on: true)
    else
      current_domain.add_url(params[:url], should_run_audits_on: true, should_scan_for_tags: false)
    end
  end

  def create_or_update_to_run_scans_on
    existing_url = current_domain.page_urls.find_by(full_url: params[:url])
    if existing_url
      existing_url.update!(should_scan_for_tags: true)
    else
      current_domain.add_url(params[:url], should_scan_for_tags: true, should_run_audits_on: false)
    end
  end

  def dont_run_audits_on
    page_url = current_domain.page_urls.find(params[:id])
    page_url.update!(should_run_audits_on: false)
  end

  def dont_scan_for_tags_on
    page_url = current_domain.page_urls.find(params[:id])
    page_url.update!(should_scan_for_tags: false)
  end
end
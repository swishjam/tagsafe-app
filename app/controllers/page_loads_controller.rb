class PageLoadsController < LoggedInController
  def index
    render_breadcrumbs(text: 'Performance')
    render_navigation_items(
      { url: root_path, text: 'Tags' },
      { url: container_change_requests_path(@container), text: 'Change Releases' },
      { url: container_page_performance_path, text: 'Page Performance' },
      { url: container_settings_path, text: 'Settings' },
    )
  end
end

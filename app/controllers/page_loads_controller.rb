class PageLoadsController < LoggedInController
  def index
    render_breadcrumbs(text: 'Performance')
    render_navigation_items(
      { url: root_path, text: 'Tags' },
      { url: change_requests_path, text: 'Change Releases' },
      { url: page_performance_path, text: 'Page Performance' },
      { url: settings_path, text: 'Settings' },
    )
  end
end

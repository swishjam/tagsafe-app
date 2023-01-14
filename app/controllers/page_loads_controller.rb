class PageLoadsController < LoggedInController
  def index
    render_breadcrumbs(text: 'Performance')
    render_navigation_items(
      { url: root_path, text: 'Tags' },
      { url: all_releases_path, text: 'Releases' },
      { url: page_performance_path, text: 'Page Performance' },
      { url: settings_path, text: 'Settings' },
    )
  end
end

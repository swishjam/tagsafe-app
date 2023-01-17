class PageLoadsController < LoggedInController
  def index
    render_breadcrumbs(
      { url: containers_path, text: @container.name },
      { text: 'Performance' }
    )
    render_navigation_items(
      { url: container_tag_snippets_path(@container), text: 'Tags' },
      { url: container_change_requests_path(@container), text: 'Change Releases' },
      { url: container_page_performance_path(@container), text: 'Page Performance' },
      { url: container_settings_path(@container), text: 'Settings' },
    )
  end
end

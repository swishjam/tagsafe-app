class ChangeRequestsController < LoggedInController
  def index
    render_breadcrumbs(text: 'Change Requests')
    render_navigation_items(
      { url: root_path, text: 'Tags' },
      { url: change_requests_path, text: 'Change Requests' },
      { url: all_releases_path, text: 'Releases' },
      { url: page_performance_path, text: 'Page Performance' },
      { url: settings_path, text: 'Settings' },
    )
  end

  def list
    render turbo_stream: turbo_stream.replace(
      "#{current_container.uid}_change_requests",
      partial: 'change_requests/list',
      locals: { 
        container: current_container,
        tags_with_open_change_requests: current_container.tags.open_change_requests,
      }
    )
  end
end
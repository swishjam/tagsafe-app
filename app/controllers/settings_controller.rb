class SettingsController < LoggedInController
  before_action { render_breadcrumbs({ text: 'Settings' }) }
  def global_settings
    render_navigation_items(
      { url: root_path, text: 'Tags' },
      { url: container_change_requests_path(@container), text: 'Change Requests' },
      { url: container_page_performance_path, text: 'Page Performance' },
      { url: container_settings_path, text: 'Settings' },
    )
  end


  def team_management
    render_breadcrumbs(
      { text: 'Settings', url: container_settings_path },
      { text: 'Team Management' },
    )
    render_navigation_items(
      { url: root_path, text: 'Tags' },
      { url: container_change_requests_path(@container), text: 'Change Requests' },
      { url: container_page_performance_path, text: 'Page Performance' },
      { url: container_settings_path, text: 'Settings', active: true },
    )
  end


  def install_script
    render_breadcrumbs(
      { text: 'Settings', url: container_settings_path },
      { text: 'Install Script' },
    )
    render_navigation_items(
      { url: root_path, text: 'Tags' },
      { url: container_change_requests_path(@container), text: 'Change Requests' },
      { url: container_page_performance_path, text: 'Page Performance' },
      { url: container_settings_path, text: 'Settings', active: true },
    )
  end

end

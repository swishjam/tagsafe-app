class SettingsController < LoggedInController
  before_action { render_breadcrumbs({ text: 'Settings' }) }
  def global_settings
    render_navigation_items(
      { url: root_path, text: 'Tags' },
      { url: change_requests_path, text: 'Change Requests' },
      { url: page_performance_path, text: 'Page Performance' },
      { url: settings_path, text: 'Settings' },
    )
  end


  def team_management
    render_breadcrumbs(
      { text: 'Settings', url: settings_path },
      { text: 'Team Management' },
    )
    render_navigation_items(
      { url: root_path, text: 'Tags' },
      { url: change_requests_path, text: 'Change Requests' },
      { url: page_performance_path, text: 'Page Performance' },
      { url: settings_path, text: 'Settings', active: true },
    )
  end


  def install_script
    render_breadcrumbs(
      { text: 'Settings', url: settings_path },
      { text: 'Install Script' },
    )
    render_navigation_items(
      { url: root_path, text: 'Tags' },
      { url: change_requests_path, text: 'Change Requests' },
      { url: page_performance_path, text: 'Page Performance' },
      { url: settings_path, text: 'Settings', active: true },
    )
  end

end

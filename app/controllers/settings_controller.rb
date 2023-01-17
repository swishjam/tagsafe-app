class SettingsController < LoggedInController

  def global_settings
    render_breadcrumbs(
      { url: containers_path, text: @container.name }, 
      { text: 'Settings' }
    )
    render_navigation_items(
      { url: container_tag_snippets_path(@container), text: 'Tags' },
      { url: container_change_requests_path(@container), text: 'Change Requests' },
      { url: container_page_performance_path(@container), text: 'Page Performance' },
      { url: container_settings_path(@container), text: 'Settings' },
    )
  end


  def team_management
    render_breadcrumbs(
      { url: containers_path, text: @container.name },
      { text: 'Settings', url: container_settings_path(@container) },
      { text: 'Team Management' },
    )
    render_navigation_items(
      { url: container_tag_snippets_path(@container), text: 'Tags' },
      { url: container_change_requests_path(@container), text: 'Change Requests' },
      { url: container_page_performance_path(@container), text: 'Page Performance' },
      { url: container_settings_path(@container), text: 'Settings', active: true },
    )
  end


  def install_script
    render_breadcrumbs(
      { url: containers_path, text: @container.name },
      { text: 'Settings', url: container_settings_path(@container) },
      { text: 'Install Script' },
    )
    render_navigation_items(
      { url: container_tag_snippets_path(@container), text: 'Tags' },
      { url: container_change_requests_path(@container), text: 'Change Requests' },
      { url: container_page_performance_path(@container), text: 'Page Performance' },
      { url: container_settings_path(@container), text: 'Settings', active: true },
    )
  end

end

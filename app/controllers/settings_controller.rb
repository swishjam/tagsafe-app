class SettingsController < LoggedInController

  def global_settings
    render_breadcrumbs(
      { url: containers_path, text: @container.name }, 
      { text: 'Settings' }
    )
    render_default_navigation_items(:settings)
  end


  def team_management
    render_breadcrumbs(
      { url: containers_path, text: @container.name },
      { text: 'Settings', url: container_settings_path(@container) },
      { text: 'Team Management' },
    )
    render_default_navigation_items(:settings)
  end


  def install_script
    render_breadcrumbs(
      { url: containers_path, text: @container.name },
      { text: 'Settings', url: container_settings_path(@container) },
      { text: 'Install Script' },
    )
    render_default_navigation_items(:settings)
  end

end

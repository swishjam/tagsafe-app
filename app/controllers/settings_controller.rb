class SettingsController < LoggedInController
  before_action { render_breadcrumbs({ text: 'Settings' }) }

  def team_management
    render_breadcrumbs(text: 'Team Management')
  end
end
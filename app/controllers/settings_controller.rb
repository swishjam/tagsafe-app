class SettingsController < LoggedInController
  before_action { render_breadcrumbs({ text: 'Settings' }) }
  def tag_management
    @tags = current_domain.tags
                          .includes(:tag_identifying_data, :tag_preferences)
                          .order('tag_identifying_data.name ASC')
                          .order('removed_from_site_at ASC')
                          .order('last_released_at DESC')
                          .page(params[:page]).per(params[:per_page] || 10)
  end
end
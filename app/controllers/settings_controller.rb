class SettingsController < LoggedInController
  def tag_management
    @tags = current_domain.tags.joins(:tag_preferences)
                          .order('tag_preferences.enabled DESC')
                          .order('removed_from_site_at ASC')
                          .order('last_released_at DESC')
  end

  def billing
  end
end
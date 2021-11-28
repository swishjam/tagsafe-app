class SettingsController < LoggedInController
  def tag_management
    @tags = current_domain.tags.joins(:tag_preferences)
                          .order('tag_preferences.enabled DESC')
                          .order('removed_from_site_at ASC')
                          .order('content_changed_at DESC')
  end

  def audit_settings
    @non_third_party_url_patterns = NonThirdPartyUrlPattern.all
  end
end
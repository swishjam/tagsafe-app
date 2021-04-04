class SlackSettingsController < LoggedInController
  def oauth_redirect
    authorizer = SlackModerator::Authorizer.new(current_organization)
    authorizer.auth!(params[:code])
    if authorizer.success
      display_toast_message('TagSafe bot has been added to your Slack workspace.')
    else
      display_toast_error(authorizer.error)
    end
    redirect_to tags_path
  end
end
class OrganizationUsersController < LoggedInController
  def destroy
    ou = OrganizationUser.find(params[:id])
    if current_user.can_remove_user_from_organization?(ou.organization)
      ou.destroy!
      display_toast_message("#{ou.user.email} removed from #{ou.organization.name}.")
      redirect_to request.referrer
    end
  end
end
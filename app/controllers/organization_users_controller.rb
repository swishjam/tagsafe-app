class OrganizationUsersController < LoggedInController
  def destroy_modal
    organization_user = current_organization.organization_users.includes(:user).find(params[:id])
    stream_modal(
      partial: 'organization_users/destroy_modal',
      locals: { organization_user: organization_user }
    )
  end

  def destroy
    ou = OrganizationUser.find(params[:id])
    if current_user.can_remove_user_from_organization?(ou.organization)
      ou.destroy!
      redirect_to request.referrer
    else
      stream_modal(
        partial: 'organization_users/destroy_modal',
        locals: { 
          organization_user: ou,
          errors: ['Insufficient access to remove user']
        }
      )
    end
  end
end
class DomainUsersController < LoggedInController
  def destroy_modal
    domain_user = current_domain.domain_users.includes(:user).find(params[:id])
    stream_modal(
      partial: 'domain_users/destroy_modal',
      locals: { domain_user: domain_user }
    )
  end

  def index
    @domain_users = current_domain.domain_users.includes(:user)
    render_breadcrumbs(text: 'Team Management')
    # render turbo_stream: turbo_stream.replace(
    #   "domain_#{current_domain.uid}_domain_users",
    #   partial: "domain_users/index",
    #   locals: {
    #   }
    # )
  end

  def destroy
    du = DomainUser.find(params[:id])
    if current_user.can_remove_user_from_domain?(du.domain)
      du.destroy!
      redirect_to request.referrer
    else
      stream_modal(
        partial: 'domain_users/destroy_modal',
        locals: { 
          domain_user: du,
          errors: ['Insufficient access to remove user']
        }
      )
    end
  end
end
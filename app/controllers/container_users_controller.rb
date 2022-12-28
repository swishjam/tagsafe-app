class ContainerUsersController < LoggedInController
  def destroy_modal
    container_user = current_container.container_users.includes(:user).find_by(uid: params[:uid])
    stream_modal(
      partial: 'container_users/destroy_modal',
      locals: { container_user: container_user }
    )
  end

  def index
    @container_users = current_container.container_users.includes(:user)
    render_breadcrumbs(text: 'Team Management')
  end

  def destroy
    du = ContainerUser.find_by(uid: params[:uid])
    if current_user.can_remove_user_from_container?(du.container)
      du.destroy!
      redirect_to request.referrer
    else
      stream_modal(
        partial: 'container_users/destroy_modal',
        locals: { 
          container_user: du,
          errors: ['Insufficient access to remove user']
        }
      )
    end
  end
end
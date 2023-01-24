class ContainerUsersController < LoggedInController
  def show
    container_user = @container.container_users.includes(:user).find_by(uid: params[:uid])
    stream_modal(
      partial: 'container_users/show',
      locals: { 
        container: @container,
        container_user: container_user 
      }
    )
  end

  def index
    render turbo_stream: turbo_stream.replace(
      "container_#{@container.uid}_container_users",
      partial: 'container_users/index',
      locals: {
        current_user: current_user,
        container: @container,
        container_users: @container.container_users.includes(:user),
      }
    )
  end

  def destroy
    cu = @container.container_users.find_by!(uid: params[:uid])
    if current_user.can_remove_user_from_container?(cu.container) && cu.destroy
      stream_modal(
        partial: 'container_users/show',
        locals: { container_user: cu, success: true }
      )
    else
      stream_modal(
        partial: 'container_users/show',
        locals: { 
          container_user: cu,
          errors: ['Insufficient access to remove user']
        }
      )
    end
  end
end
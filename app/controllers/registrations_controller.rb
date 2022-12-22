class RegistrationsController < LoggedOutController
  skip_before_action :verify_authenticity_token
  def new
    redirect_to root_path if current_user.present?
    @hide_logged_out_nav = true
    @hide_footer = true
    @user = User.new
    if params[:container]
      @container = Container.find_by(uid: params[:container])
    end
  end

  def create
    @user = User.new(user_params)
    if @user.save
      if current_container
        current_container.add_user(@user)
        current_container.mark_as_registered!
        Role.USER_ADMIN.apply_to_container_user(@user.container_user_for(current_container))
        set_current_user(@user)
        redirect_to root_path
      else
        set_current_user(@user)
        redirect_to new_registration_path
      end
    else
      display_inline_errors(@user.errors.full_messages)
      @hide_logged_out_nav = true
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:email, :first_name, :last_name, :password)
  end
end
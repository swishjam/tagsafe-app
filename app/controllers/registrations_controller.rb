class RegistrationsController < LoggedOutController
  skip_before_action :verify_authenticity_token

  def new
    @hide_logged_out_nav_items = true
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if params[:invite_code] == ENV['INVITE_CODE']
      if @user.save
        Role.USER_ADMIN.assign_to(@user)
        log_user_in(@user)
        redirect_to new_organization_path
      else
        display_inline_errors(@user.errors.full_messages)
        render :new, status: :unprocessable_entity
      end
    else
      display_inline_errors(['Invalid invite code.'])
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:email, :first_name, :last_name, :password)
  end
end
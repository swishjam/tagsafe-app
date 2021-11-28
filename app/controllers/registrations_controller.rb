class RegistrationsController < LoggedOutController
  skip_before_action :verify_authenticity_token

  def new
    @user = User.new
  end

  def create
    user = User.new(user_params)
    if user.save
      Role.USER_ADMIN.assign_to(user)
      log_user_in(user)
      redirect_to new_organization_path
    else
      display_inline_errors(user.errors.full_messages)
      redirect_to new_registration_path
    end
  end

  private

  def user_params
    params.require(:user).permit(:email, :first_name, :last_name, :password)
  end
end
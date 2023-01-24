class RegistrationsController < LoggedOutController
  skip_before_action :verify_authenticity_token
  
  def new
    redirect_to containers_path if current_user.present?
    if params[:invite_token]
      @user_invite = UserInvite.find_by(token: params[:invite_token])
    end
  end

  def create
    user = User.new(user_params)
    user_invite = params[:invite_token] ? UserInvite.find_by(token: params[:invite_token]) : nil
    if user.save
      set_current_user(user)
      user_invite.redeem!(user) if user_invite && user_invite.redeemable?
      url_to_go_to = session[:redirect_url] || containers_path
      session.delete(:redirect_url)
      redirect_to url_to_go_to
    else
      render turbo_stream: turbo_stream.replace(
        'registration_form',
        partial: 'registrations/form',
        locals: { 
          user: user,
          user_invite: user_invite,
        }
      )
    end
  end

  private

  def user_params
    params.require(:user).permit(:email, :first_name, :last_name, :password)
  end
end
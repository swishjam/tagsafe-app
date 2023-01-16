class RegistrationsController < LoggedOutController
  skip_before_action :verify_authenticity_token
  
  def new
    redirect_to root_path if current_user.present?
  end

  def create
    user = User.new(user_params)
    if user.save
      set_current_user(user)
      url_to_go_to = session[:redirect_url] || root_path
      session.delete(:redirect_url)
      redirect_to url_to_go_to
    else
      render turbo_stream: turbo_stream.replace(
        'registration_form',
        partial: 'registrations/form',
        locals: { user: user }
      )
    end
  end

  private

  def user_params
    params.require(:user).permit(:email, :first_name, :last_name, :password)
  end
end
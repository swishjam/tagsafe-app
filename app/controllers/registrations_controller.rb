class RegistrationsController < LoggedOutController
  skip_before_action :verify_authenticity_token

  def new
    @hide_logged_out_nav = true
    @user = User.new
    if params[:domain]
      @domain = Domain.find_by(uid: params[:domain])
    end
  end

  def create
    @user = User.new(user_params)
    @domain = Domain.find_by(uid: params[:domain_uid]) if params[:domain_uid]
    if params[:invite_code] == ENV['INVITE_CODE']
      if @user.save
        if @domain
          @domain.add_user(@user)
          @domain.mark_as_registered!
          log_user_in(@user)
          url_to_go_to = session[:redirect_url] || params[:redirect_url] || tags_path
          session.delete(:redirect_url)
          redirect_to url_to_go_to
        else
          log_user_in(@user)
          redirect_to new_domain_path
        end
      else
        display_inline_errors(@user.errors.full_messages)
        @hide_logged_out_nav = true
        render :new, status: :unprocessable_entity
      end
    else
      display_inline_errors(['Invalid invite code.'])
      @hide_logged_out_nav = true
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:email, :first_name, :last_name, :password)
  end
end
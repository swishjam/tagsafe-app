class RegistrationsController < LoggedOutController
  skip_before_action :verify_authenticity_token

  def domain
    redirect_to new_registration_path if current_domain.present?
    @hide_logged_out_nav = true
    @hide_footer = true
    @domain = Domain.new
  end

  def new
    redirect_to domain_registrations_path if current_domain.nil?
    redirect_to select_subscription_plans_path if current_user.present?
    @hide_logged_out_nav = true
    @hide_footer = true
    @user = User.new
    if params[:domain]
      @domain = Domain.find_by(uid: params[:domain])
    end
  end

  def create
    @user = User.new(user_params)
    if params[:invite_code] == ENV['INVITE_CODE']
      if @user.save
        if current_domain
          current_domain.add_user(@user)
          current_domain.mark_as_registered!
          Role.USER_ADMIN.apply_to_domain_user(@user.domain_user_for(current_domain))
          set_current_user(@user)
          redirect_to select_subscription_plans_path
        else
          set_current_user(@user)
          redirect_to domain_registrations_path
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
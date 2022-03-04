class UserInvitesController < LoggedInController
  skip_before_action :authorize!, only: [:accept, :redeem]
  skip_before_action :ensure_organization, only: [:accept, :redeem]
  skip_before_action :ensure_domain, only: [:accept, :redeem]
  layout 'logged_out_layout', only: :accept

  def new
    @user_invite = UserInvite.new
    # @organization_users = OrganizationUser.includes(:user).where(organization_id: current_organization.id).where.not(user_id: current_user.id)
    @organization_users = current_organization.organization_users.includes(:user)
    @pending_invites = current_organization.user_invites.not_redeemed
  end

  def create
    invite = current_user.invite_user_to_organization!(params[:user_invite][:email], current_organization)
    if invite.valid?
      current_user.broadcast_notification(message: "Invite sent to #{params[:user_invite][:email]}")
      render turbo_stream: turbo_stream.replace(
        "organization_#{current_organization.uid}_pending_invites",
        partial: 'user_invites/index',
        locals: { user_invites: current_organization.user_invites.not_redeemed }
      )
    else
      render turbo_stream: turbo_stream.replace(
        "organization_#{current_organization.uid}_invite_form",
        partial: 'user_invites/form',
        locals: { errors: invite.errors.full_messages }
      )
    end
  end

  def accept
    @user = User.new
    @user_invite = UserInvite.includes(:organization).find_by(token: params[:token])
    @hide_logged_out_nav = true
    unless @user_invite.redeemable?
      display_inline_error("Invite expired. Please request a new invite from your admin.")
      redirect_to root_path
    end
  end

  def redeem
    # TODO: this assumes a new user will always be created
    # need to take into account users that already have a Tagsafe account
    invite = UserInvite.find_by(token: params[:token])
    if invite.redeemable?
      user = User.create(user_params)
      if user.valid?
        invite.redeem!(user)
        log_user_in(user)
        redirect_to tags_path
      else
        display_inline_errors(user.errors.full_messages)
        redirect_to request.referrer
      end
    else
      display_inline_error("Invite expired. Please request a new invite from your admin.")
      redirect_to request.referrer
    end
  end

  private 

  def user_params
    params.require(:user).permit(:email, :password, :first_name, :last_name)
  end
end
class UserInvitesController < LoggedInController
  skip_before_action :find_and_validate_container, only: [:accept, :redeem]

  def new
    @user_invite = UserInvite.new
    stream_modal(
      partial: 'user_invites/form',
      locals: { 
        user_invite: UserInvite.new, 
        container: @container 
      }
    )
  end

  def create
    invite = current_user.invite_user_to_container!(params[:user_invite][:email], @container)
    if invite.valid?
      stream_modal(
        partial: 'user_invites/form',
        locals: { 
          completed: true,
          invited_user_email: invite.email
        }
      )
    else
      stream_modal(
        partial: 'user_invites/form',
        locals: { 
          container: @container,
          user_invite: invite,
          completed: false
        }
      )
    end
  end

  def index
    @pending_user_invites = @container.user_invites.pending.page(params[:page] || 1).per(params[:per_page] || 20)
  end

  def accept
    @user = User.new
    @user_invite = UserInvite.includes(:container).find_by(token: params[:token])
    @hide_footer = true
    @hide_logged_out_nav = true
    render :accept, layout: 'logged_out_layout'
  end

  def redeem
    # TODO: this assumes a new user will always be created
    # need to take into account users that already have a Tagsafe account
    invite = UserInvite.find_by(token: params[:token])
    if invite.redeemable?
      user = User.create(user_params)
      if user.valid?
        invite.redeem!(user)
        set_current_user(user)
        redirect_to root_path
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
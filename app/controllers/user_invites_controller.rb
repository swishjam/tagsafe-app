class UserInvitesController < ApplicationController
  layout 'purgatory'

  def new
    @user_invite = UserInvite.new
  end

  def create
    invite = current_user.invite_user_to_organization!(params[:user_invite][:email])
    if invite.valid?
      display_toast_message("Invite sent to #{params[:user_invite][:email]}")
    else
      display_toast_errors(invite.errors.full_messages)
    end
    redirect_to request.referrer
  end

  def accept
    @user = User.new
    @user_invite = UserInvite.includes(:organization).find_by(token: params[:token])
    unless @user_invite.reedemable?
      display_toast_error("Invite expired. Please request a new invite from your admin.")
      redirect_to root_path
    end
  end

  def redeem
    invite = UserInvite.find_by(token: params[:token])
    if invite.reedemable?
      params[:user][:organization_id] = invite.organization_id
      user = User.create(user_params)
      if user.valid?
        invite.redeem!
        display_toast_message("Invite accepted successfully. Welcome to TagSafe!")
        redirect_to scripts_path
      else
        display_inline_errors(user.errors.full_messages)
        redirect_to request.referrer
      end
    else
      display_toast_error("Invite expired. Please request a new invite from your admin.")
      redirect_to root_path
    end
  end

  private 

  def user_params
    params.require(:user).permit(:email, :password, :organization_id)
  end
end
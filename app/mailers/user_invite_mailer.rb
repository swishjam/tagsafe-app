class UserInviteMailer < ApplicationMailer
  def send_invite_email(user_invite)
    @invited_by_user = user_invite.invited_by_user
    @organization = user_invite.organization
    @token = user_invite.token
    @accept_invite_url = "#{ENV['CURRENT_HOST']}/invite/#{@token}/accept"
    mail(to: user_invite.email, subject: "You've been invited to TagSafe.")
  end
end
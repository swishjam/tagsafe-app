module TagsafeEmail
  class Invitation < Base
    self.sendgrid_template_id = :'d-bebad09b57fa4c0aa850cbed2734513c'
    self.from_email = :'notifications@tagsafe.io'

    def initialize(user_invite)
      @to_email = user_invite.email
      @template_variables = {
        container_name: user_invite.container.name,
        accept_invite_url: mail_safe_url("/user_invites/#{user_invite.token}/accept"),
        inviter_name: user_invite.invited_by_user.full_name
      }
    end
  end
end
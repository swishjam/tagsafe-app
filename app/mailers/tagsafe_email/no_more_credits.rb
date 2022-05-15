module TagsafeEmail
  class NoMoreCredits < Base
    self.from_email = :'notifications@tagsafe.io'

    def initialize(user)
      @to_email = user.email
      @template_variables = {
        user_name: user.first_name,
        add_more_credits_url: mail_safe_url("/settings/billing")
      }
    end
  end
end
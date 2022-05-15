module TagsafeEmail
  class LowCreditsWarning < Base
    self.from_email = :'notifications@tagsafe.io'

    def initialize(user, credit_wallet)
      @to_email = user.email
      @template_variables = {
        user_name: user.first_name,
        wallet: credit_wallet,
        add_more_credits_url: mail_safe_url("/settings/billing")
      }
    end
  end
end
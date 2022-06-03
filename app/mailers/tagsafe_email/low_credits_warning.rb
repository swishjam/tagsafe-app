module TagsafeEmail
  class LowCreditsWarning < Base
    self.from_email = :'notifications@tagsafe.io'

    def initialize(user, credit_wallet)
      @to_email = user.email
      @template_variables = {
        user_name: user.first_name,
        domain_url: credit_wallet.domain.url_hostname,
        month: Date::MONTHNAMES[credit_wallet.month],
        total_credits_for_month: credit_wallet.total_credits_for_month,
        credits_used: credit_wallet.credits_used,
        credits_remaining: credit_wallet.credits_remaining,
        add_more_credits_url: mail_safe_url("/settings/billing?_domain_uid=#{credit_wallet.domain.uid}")
      }
    end
  end
end
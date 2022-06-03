module TagsafeEmail
  class PaymentFailed < Base
    self.from_email = :'notifications@tagsafe.io'
    self.sendgrid_template_id = :'d-aa004cebdbba4998b7abf6cfb156e163'

    def initialize(user, subscription_plan)
      @to_email = user.email
      @template_variables = {
        user_name: user.first_name,
        domain_url: subscription_plan.domain.url_hostname,
        update_payment_url: mail_safe_url("/settings/billing?_domain_uid=#{subscription_plan.domain.uid}")
      }
    end
  end
end
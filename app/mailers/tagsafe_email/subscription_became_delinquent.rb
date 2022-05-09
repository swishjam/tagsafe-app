module TagsafeEmail
  class SubscriptionBecameDelinquent < Base
    self.from_email = :'subscriptions@tagsafe.io'
    self.sendgrid_template_id = :'d-abe2eeaa89f947849cd13910fe8d982c'

    def initialize(user, domain)
      @to_email = user.email
      @template_variables = {
        user_name: user.first_name,
        update_payment_method_url: mail_safe_url("/settings/billing")
      }
    end
  end
end
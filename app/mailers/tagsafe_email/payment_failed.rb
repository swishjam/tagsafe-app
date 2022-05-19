module TagsafeEmail
  class PaymentFailed < Base
    self.from_email = :'notifications@tagsafe.io'
    self.sendgrid_template_id = :'d-aa004cebdbba4998b7abf6cfb156e163'

    def initialize(user)
      @to_email = user.email
      @template_variables = {
        user_name: user.first_name,
        update_payment_url: mail_safe_url("/settings/billing")
      }
    end
  end
end
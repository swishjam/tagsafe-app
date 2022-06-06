module TagsafeEmail
  class PaymentSucceeded < Base
    self.from_email = :'notifications@tagsafe.io'
    self.sendgrid_template_id = :'d-ccbfc4da04e54684aceab87d6bbe88bc'

    def initialize(user:, subscription_plan:, stripe_invoice_amount:, stripe_invoice_start_date:, stripe_invoice_end_date:)
      @to_email = user.email
      @template_variables = {
        user_name: user.first_name,
        domain_url: subscription_plan.domain.url_hostname,
        formatted_amount: "$#{sprintf('%.2f', stripe_invoice_amount / 100.0)}",
        invoice_period: "#{Time.at(stripe_invoice_start_date).to_datetime.strftime('%A, %B %d %I:%M %p (%Z)')} - #{Time.at(stripe_invoice_end_date).to_datetime.strftime('%A, %B %d %I:%M %p (%Z)')}"
      }
    end
  end
end
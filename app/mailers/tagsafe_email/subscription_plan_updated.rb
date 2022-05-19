module TagsafeEmail
  class SubscriptionPlanUpdated < Base
    self.from_email = :'notifications@tagsafe.io'
    self.sendgrid_template_id = :'d-f60cccaa5e8049659d0bfd98a39ec0a6'

    def initialize(
      user, 
      subscription_plan, 
      previous_amount:, 
      new_amount:,
      next_payment_amount:, 
      next_payment_date:
    )
      @to_email = user.email
      @template_variables = {
        user_first_name: user.first_name,
        domain_url: subscription_plan.domain.url_hostname,
        billing_interval: subscription_plan.billing_interval_with_ly,
        subscription_package_friendly_name: subscription_plan.human_package_type,
        formatted_previous_price: "$#{sprintf('%.2f', previous_amount / 100.0)}",
        formatted_new_price: "$#{sprintf('%.2f', new_amount / 100.0)}",
        next_payment_amount: "$#{sprintf('%.2f', next_payment_amount / 100.0)}",
        next_payment_date: next_payment_date,
      }
    end
  end
end
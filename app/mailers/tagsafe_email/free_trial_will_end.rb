module TagsafeEmail
  class FreeTrialWillEnd < Base
    self.from_email = :'subscriptions@tagsafe.io'
    self.sendgrid_template_id = :'d-9c475f07c8114f7ea9e37702b46e4709'

    def initialize(user, subscription_plan)
      @to_email = user.email
      @template_variables = {
        free_trial_end_date: subscription_plan.free_trial_ends_at.formatted_long,
        subscription_package: subscription_plan.human_package_type,
        has_payment_method_on_file: subscription_plan.domain.has_payment_method_on_file?,
        subscription_amount: "$#{sprintf('%.2f', Stripe::Invoice.upcoming({ subscription: subscription_plan.domain.current_saas_subscription_plan.stripe_subscription_id }).amount_due / 100.0)}",
        update_payment_method_url: mail_safe_url("/settings/billing")
      }
    end
  end
end
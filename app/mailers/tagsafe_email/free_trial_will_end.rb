module TagsafeEmail
  class FreeTrialWillEnd < Base
    self.from_email = :'subscriptions@tagsafe.io'
    self.sendgrid_template_id = :'TODO'

    def initialize(user, subscription_plan)
      @to_email = user.email
      @template_variables = {
        free_trial_end_date: subscription_plan.free_trial_ends_at,
        subscription_package_type: subscription_plan.package_type
      }
    end
  end
end
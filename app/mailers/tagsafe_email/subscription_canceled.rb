module TagsafeEmail
  class SubscriptionCanceled < Base
    self.from_email = :'notifications@tagsafe.io'
    self.sendgrid_template_id = :'d-3bf1b351bfd04389a700d4657dd2c9e6'
    
    def initialize(user, subscription_plan)
      @to_email = user.email
      @template_variables = { 
        user_name: user.first_name,
        domain_url: subscription_plan.domain.hostname
      }
    end
  end
end
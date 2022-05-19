module TagsafeEmail
  class Welcome < Base
    self.from_email = :'collin@tagsafe.io'
    self.sendgrid_template_id = :'d-d81a98be70b24f1b811b3087598a54d9'

    def initialize(user)
      @to_email = user.email
      @from_email = from_email
      @template_variables = { 
        first_name: user.first_name,
        dashboard_url: mail_safe_url("/tags")
      }
    end
  end
end
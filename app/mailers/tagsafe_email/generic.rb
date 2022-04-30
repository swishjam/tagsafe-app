module TagsafeEmail
  class Generic < Base
    self.sendgrid_template_id = :'d-7493482135c6422e8909702051fb4615'

    def initialize(to_email:, from_email: :'notifications@tagsafe.io', body:, subject:)
      @to_email = to_email
      @from_email = from_email
      @template_variables = {
        body: body,
        subject: subject
      }
    end
  end
end
module TagsafeEmail
  class <%= class_name %> < Base
    self.sendgrid_template_id = :''
    self.from_email = :'alerts@tagsafe.io'

    def initialize(user:, alert_configuration:, initiating_record:, triggered_alert:)
      @to_email = user.email
      @template_variables = {}
    end
  end
end
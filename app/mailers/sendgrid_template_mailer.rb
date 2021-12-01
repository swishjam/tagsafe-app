require 'sendgrid-ruby'
include SendGrid

class SendgridTemplateMailer
  class << self
    TEMPLATE_ID_DICTIONARY = {
      welcome: "d-79b391be0eba4a6492f2c7eda4fc9a6d",
      user_invite: "d-dab9d8be361e4c0eb05428b63b1c4136",
      new_tag: "d-49852daabc35489b95bb4d45e93ff10c", # updated
      audit_completed: "d-2dd39f47bfcb4b0f857ad86158721c7b",
      new_tag_version: "d-588eaf33c727495b8e64c6113d64449c", # updated
      generic: 'd-7493482135c6422e8909702051fb4615' # updated
    }
    
    def send!
      raise TagSafeMailerError::InvalidArgumentsError, "Missing required SendgridTemplateMailer arguments. Must include `@to_email`, `@variable_json`, `@from_email`, and `@template_name`" if @to_email.nil? || @variable_json.nil? || @from_email.nil? || @template_name.nil?
      data = {
        "personalizations": [
          {
            "to": [
              {
                "email": "#{@to_email}"
              }
            ],
            "dynamic_template_data": @variable_json
          }
        ],
        "from": {
          "email": "#{@from_email}"
        },
        "template_id": "#{TEMPLATE_ID_DICTIONARY[@template_name]}"
      }
      Rails.logger.info "Sending #{@template_name} (#{TEMPLATE_ID_DICTIONARY[@template_name]}) email to #{@to_email}"
      resp = sg_api.client.mail._("send").post(request_body: data)
      Rails.logger.error "Sendgrid Post err: #{resp.status_code} - #{resp.body}" unless resp.status_code.to_i < 300
    end

    def sg_api
      @sg_api ||= SendGrid::API.new(api_key: ENV['SENDGRID_API_KEY'])
    end
  end
end
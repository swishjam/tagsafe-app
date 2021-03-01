class SendgridTemplateMailer
  class << self
    TEMPLATE_ID_DICTIONARY = {
      welcome: "d-79b391be0eba4a6492f2c7eda4fc9a6d",
      user_invite: "d-dab9d8be361e4c0eb05428b63b1c4136",
      new_tag: "d-274bfb60a27a4a4a9c1b2700ad8ccc0c",
      audit_completed: "d-2dd39f47bfcb4b0f857ad86158721c7b",
      tag_changed: "d-f982057c412f44b5aa825c62886b6ed0"
    }
    
    def send!
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
      sg_api.client.mail._("send").post(request_body: data)
    end

    def sg_api
      @sg_api ||= SendGrid::API.new(api_key: ENV['SENDGRID_API_KEY'])
    end
  end
end
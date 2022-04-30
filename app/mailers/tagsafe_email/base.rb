module TagsafeEmail
  class Base
    class << self
      attr_accessor :sendgrid_template_id, :from_email
    end

    def send!
      resp = self.class.sg_api.client.mail._("send").post(request_body: sendgrid_request_body)
      on_delivery_failure(resp) if resp.status_code.to_i > 299
    end

    private

    def mail_safe_url(path)
      "#{ENV['CURRENT_HOST'] || 'https://www.tagsafe.io'}#{path}"
    end

    def on_delivery_failure(sendgrid_response)
      raise TagsafeEmailError::Invalid, "Unable to deliver #{self.class.to_s}\nto: #{to_email}\nfrom: #{from_email}\n#{JSON.parse(sendgrid_response.body)['errors'].collect{ |h| h['message'] }.join('. ')}"
    # rescue => e
    #   raise TagsafeEmailError::Invalid, "Unable to deliver #{self.class.to_s}: #{sendgrid_response.inspect}"
    end

    def template_variables
      @template_variables || {}
    end

    def to_email
      @to_email || begin raise TagsafeEmailError::Invalid, "Subclass #{self.class.to_s} must implement `to_email`"; end;
    end

    def from_email
      self.class.from_email || @from_email || begin raise TagsafeEmailError::Invalid, "Subclass #{self.class.to_s} must implement `from_email`"; end;
    end

    def sendgrid_request_body
      raise TagsafeEmailError::Invalid, "Subclass #{self.class.to_s} must implement `sendgrid_template_id` class attr_accessor" if self.class.sendgrid_template_id.nil?
      Rails.logger.info "Sending #{self.class.to_s} email to: #{to_email}, from: #{from_email}..."
      {
        personalizations: [
          {
            dynamic_template_data: template_variables,
            to: [{ email: to_email }]
          }
        ],
        from: { email: from_email },
        template_id: self.class.sendgrid_template_id
      }
    end

    def self.sg_api
      @sg_api ||= SendGrid::API.new(api_key: ENV['SENDGRID_API_KEY'])
    end
  end
end
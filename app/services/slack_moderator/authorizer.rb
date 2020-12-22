module SlackModerator
  class Authorizer
    attr_accessor :success, :error

    def initialize(organization)
      @organization = organization
    end

    def auth!(code)
      resp = auth_request(code)
      Rails.logger.info "Received Slack OAuth response: #{JSON.stringify(resp)}"
      handle_response(resp)
    end

    private

    def auth_request(code)
      HTTParty.post("https://slack.com/api/oauth.v2.access?
                      code=#{code}&
                      client_id=#{ENV['SLACK_CLIENT_ID']}&
                      client_secret=#{ENV['SLACK_CLIENT_SECRET']}&
                      redirect_uri=#{ENV['SLACK_OAUTH_REDIRECT_URI']}")
    end

    def handle_response(response)
      success = response['ok']
      if success
        add_slack_settings(response)
      else
        error = response['error']
      end
    end

    def add_slack_settings(response)
      @organization.slack_settings.nil? ? create_slack_settings(response) : update_slack_settings(response)
    end

    def update_slack_settings(response)
      @organization.slack_settings.update(mapped_response_attributes(response))
    end

    def create_slack_settings(response)
      SlackSetting.create({ organization: @organization }.merge!(mapped_response_attributes(response)))
    end

    def mapped_response_attributes(response)
      { access_token: response['access_token'], app_id: response['app_id'], team_id: response['team']['id'], team_name: response['team']['name'] }
    end
  end
end
module SlackModerator
  class Client
    def initialize(slack_settings)
      @slack_settings = slack_settings
    end
  
    def client
      @client ||= Slack::Web::Client.new(token: @slack_settings.access_token)
    end
  
    def notify!(message: nil, channel:, blocks: nil)
      args = message ? { channel: channel, text: message } : { channel: channel, blocks: blocks }
      client.chat_postMessage(args)
    end
  
    def get_channels
      client.conversations_list
    end
  
    def get_channel_info(channel)
      client.conversation_info(channel)
    end
  end
end
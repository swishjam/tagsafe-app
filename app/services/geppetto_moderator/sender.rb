class GeppettoModerator::Sender
  class GeppettoConnectionError < StandardError; end;

  def initialize(path_endpoint, domain, request_body)
    @endpoint = "#{ENV['GEPPETTO_DOMAIN']}#{path_endpoint}"
    @domain = domain
    @request_body = request_body
  end

  def send!
    Rails.logger.info "Sending Geppetto Request to #{@endpoint} with #{merged_request_options}"
    response = send_geppetto_request
    Rails.logger.info "Result: #{response.code} - #{response.response.body}" if response
  end

  private

  def send_geppetto_request
    HTTParty.post(@endpoint, merged_request_options)
  rescue => e
    Rails.logger.error "Could not connect to Geppetto Service. #{e}"
    raise GeppettoConnectionError, "Could not connect to Geppetto Service. #{e}"
  end
  
  def merged_request_options
    { 
      body: @request_body.to_json,
      headers: { 
        'Content-Type': 'application/json',
        'Geppetto-API-Key': 'ABC123'
        # 'Geppetto-API-Key': ENV['GEPPETTO_API_KEY']
      }
    }
  end
end


# aws_client = Aws::Lambda::Client.new({ region: 'us-east-1' })

# resp = aws_client.invoke({
#   function_name: 'url-crawler-production-crawl',
#   invocation_type: 'Event',
#   payload: JSON.generate({ url: 'https://www.canadiantire.ca' })
# })
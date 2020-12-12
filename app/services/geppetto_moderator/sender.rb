class GeppettoModerator::Sender
  def initialize(path_endpoint, domain, request_body)
    @endpoint = "#{ENV['GEPPETTO_DOMAIN']}#{path_endpoint}"
    @domain = domain
    @request_body = request_body
  end

  def send!
    Rails.logger.info "Sending Geppetto Request to #{@endpoint} with #{merged_request_options}"
    response = send_geppetto_request
    Rails.logger.info "Result: #{response.code} - #{response.response.body}"
    # geppetto_job.complete! unless response.code == 200 # never enqueued in Geppetto
  end

  private

  def send_geppetto_request
    HTTParty.post(@endpoint, merged_request_options)
  rescue => e
    Rails.logger.error "Could not connect to Geppetto Service. #{e}"
    err = Struct.new(:code, :response)
    err.new(500, { message: "An error occurred: #{e}" })
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
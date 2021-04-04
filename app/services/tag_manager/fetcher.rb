module TagManager
  class Fetcher
    attr_accessor :url, :response_time_ms, :response, :response_code
    def initialize(url)
      @url = url
    end

    def fetch!
      fetch_with_meta_data
      response
    end

    def success
      response_code > 199 && response_code < 300
    end

    private

    def fetch_with_meta_data
      start_seconds = Time.now
      @response = safe_fetch
      @response_time_ms = (Time.now - start_seconds)*1000
      @response_code = @response.code
    end

    def safe_fetch
      @response = HTTParty.get(@url)
    rescue => e
    # rescue Errno::ECONNREFUSED, OpenSSL::SSL::SSLError
      Rails.logger.info "Error fetching respones from #{url}: #{e.inspect}"
      OpenStruct.new(code: 0, response_time_ms: 0)
    end
  end
end
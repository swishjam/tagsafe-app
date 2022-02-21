module TagManager
  class ContentFetcher
    attr_accessor :response, :tag_check
    
    def initialize(tag)
      @tag = tag
    end

    def fetch!
      fetch_with_meta_data
    end

    def success?
      @response_code > 199 && @response_code < 300
    end

    private

    def fetch_with_meta_data
      start_seconds = Time.now
      response = safe_fetch
      response_time_ms = (Time.now - start_seconds)*1000
      # is 404 the right response code if response body is nil?
      @response_code = response.body.nil? ? 404 : response.code
      capture_tag_check_if_necessary!(response_time_ms, @response_code)
      response.body
    end

    def safe_fetch
      HTTParty.get(@tag.full_url)
    rescue => e
    # rescue Errno::ECONNREFUSED, OpenSSL::SSL::SSLError
      Rails.logger.info "Error fetching respsone from #{@tag.full_url}: #{e.inspect}"
      OpenStruct.new(code: 0, response_time_ms: 0)
    end

    def capture_tag_check_if_necessary!(response_time, response_code)
      if @tag.tag_preferences.should_log_tag_checks
        @tag_check = TagCheck.create(response_time_ms: response_time, response_code: response_code, tag: @tag)
      end
    end
  end
end
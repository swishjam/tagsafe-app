# module TagManager
#   class ContentFetcher
#     attr_accessor :response_body, :response_code, :response_time_ms
    
#     def initialize(tag)
#       @tag = tag
#     end

#     def fetch!
#       fetch_content_with_timing
#     end

#     def success?
#       @response_code > 199 && @response_code < 300
#     end

#     private

#     def fetch_content_with_timing
#       start_seconds = Time.now
#       response = safely_fetch_content_from_endpoint
#       @response_time_ms = (Time.now - start_seconds)*1000
#       @response_code = response.code
#       @response_body = response.body
#     end

#     def safely_fetch_content_from_endpoint
#       HTTParty.get(@tag.full_url)
#     rescue => e
#     # rescue Errno::ECONNREFUSED, OpenSSL::SSL::SSLError
#       Sentry.capture_exception(e)
#       Rails.logger.error "Error fetching respsone from #{@tag.full_url}: #{e.inspect}"
#       OpenStruct.new(code: 504, body: nil)
#     end
#   end
# end
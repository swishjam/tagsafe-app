class ScriptManager::Fetcher
  attr_accessor :url, :response_time_ms, :response, :response_code
  def initialize(url)
    @url = url
  end

  def fetch!
    fetch_with_meta_data
    response
  end

  private

  def fetch_with_meta_data
    start_seconds = Time.now
    @response = HTTParty.get(@url)
    @response_time_ms = (Time.now - start_seconds)*1000
    @response_code = @response.code
  end
end
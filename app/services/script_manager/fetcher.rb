class ScriptManager::Fetcher
  attr_accessor :content, :hashed_content, :bytes

  def initialize(url)
    @url = url
  end

  def fetch_and_format!
    response = fetch!
    # fake_response = Struct.new(:body)
    # response = fake_response.new("Collin Schneider")
    format_response(response)
  end

  def fetch!
    HTTParty.get(@url)
  end

  private

  def format_response(response)
    {
      content: response.body,
      hashed_content: ScriptManager::Hasher.hash!(response.body),
      bytes: response.body.bytesize
    }
  end
end
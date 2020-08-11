class ScriptManager::Fetcher
  attr_accessor :content, :hashed_content, :bytes

  def initialize(url)
    @url = url
  end

  def fetch!
    response = HTTParty.get(@url)
    # fake_response = Struct.new(:body)
    # response = fake_response.new("Collin Schneider")
    format_response(response)
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
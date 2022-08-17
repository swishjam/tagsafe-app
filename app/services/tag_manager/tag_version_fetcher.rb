module TagManager
  class TagVersionFetcher
    class InvalidFetch < StandardError; end;
    class InvalidTagUrl < StandardError; end;
    
    MOCKED_USER_AGENT = 'Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:59.0) Gecko/20100101 Firefox/59.0'

    def initialize(tag)
      @tag = tag
    end

    def fetch_and_capture_first_tag_version!
      content = fetch_tag_content!
      capture_tag_content!(content)
    end

    private

    def fetch_tag_content!
      raise InvalidFetch, "Cannot fetch and capture TagVersion for a Tag that already has a TagVersion" if @tag.tag_versions.any?
      resp = HTTParty.get(@tag.full_url, headers: { 'User-Agent': MOCKED_USER_AGENT })
      raise InvalidTagUrl, "Invalid Tag #{@tag.full_url}, endpoint returned a #{resp.code} response." unless resp.code < 300
      resp.to_s
    end

    def capture_tag_content!(content)
      TagManager::TagVersionCapturer.new(
        tag: @tag, 
        content: content, 
        release_check: nil, 
        hashed_content: Digest::MD5.hexdigest(content), 
        bytes: content.bytesize
      ).build_new_tag_version!
    end
  end
end
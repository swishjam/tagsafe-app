module TagManager
  class MarkTagAsTagsafeHostedIfPossible
    def initialize(tag)
      @tag = tag
    end

    def determine!
      # TODO: need logic to determine if JS is static / dynamic
      @tag.update!(is_tagsafe_hosted: true)
      TagManager::TagVersionFetcher.new(@tag).fetch_and_capture_first_tag_version!
    end
  end
end
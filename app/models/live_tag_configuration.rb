class LiveTagConfiguration < TagConfiguration
  before_create :build_first_tag_version, if: -> { is_tagsafe_hosted }

  private

  def build_first_tag_version
    return unless is_tagsafe_hosted
    TagManager::TagVersionFetcher.new(tag).fetch_and_capture_first_tag_version!
  rescue TagManager::TagVersionFetcher::InvalidTagUrl, TagManager::TagVersionFetcher::InvalidFetch => e
    errors.add(:base, e.message)
  end
end
module TagManager
  class NewTagVersionDetector
    def initialize(tag, fetched_content)
      @tag = tag
      @fetched_content = fetched_content
    end

    def detected_new_tag_version?
      return true if @tag.has_no_versions?
      if should_detect_changes_based_on_bytesize_changes?
        bytesize_changed?
      else
        hash_changed?
      end
    end

    def new_hashed_content
      @new_hashed_content ||= TagManager::Hasher.hash!(@fetched_content)
    end

    private

    def should_detect_changes_based_on_bytesize_changes?
      Flag.flag_is_true_for_objects(@tag, @tag.domain, slug: 'should_detect_new_releases_based_on_bytesize_changes')
    end

    def hash_changed?
      new_hashed_content != @tag.current_version.hashed_content
    end

    def bytesize_changed?
      @fetched_content.bytesize != @tag.current_version.bytes
    end

    # def content_changed_significantly?
    #   @content_changed_significantly ||= TagManager::GitDiffEvaluator.new(@fetched_content, @current_tagsafe_version_content).content_changed_significantly?
    # end
  end
end
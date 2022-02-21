module TagManager
  class NewTagVersionDetector
    def initialize(tag, fetched_content)
      @tag = tag
      @fetched_content = fetched_content
    end

    def detected_new_tag_version?
      return true if @tag.has_no_versions?
      auto_set_bytesize_changes_flag_based_on_tag_version_frequency_if_necessary!
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

    def auto_set_bytesize_changes_flag_based_on_tag_version_frequency_if_necessary!
      last_twenty_tag_checks = @tag.tag_checks.most_recent_first.limit(20)
      num_of_last_twenty_tag_checks_captured_new_tag_version = last_twenty_tag_checks.select{ |tc| tc.captured_new_tag_version? }.count
      if num_of_last_twenty_tag_checks_captured_new_tag_version > 5
        Rails.logger.info "AUTOMATICALLY SETTING `should_detect_new_releases_based_on_bytesize_changes` Flag for Tag #{@tag.uid} because #{num_of_last_twenty_tag_checks_captured_new_tag_version} of the last #{last_twenty_tag_checks.count} TagChecks captured a new tag version, indicating the hashed content of the JS file is changing but they're likely just different compiled versions."
        Flag.set_flag_for_object(@tag, 'should_detect_new_releases_based_on_bytesize_changes', true.to_s)
      end
    end

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
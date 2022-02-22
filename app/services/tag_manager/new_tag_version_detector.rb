module TagManager
  class NewTagVersionDetector
    def initialize(tag, fetched_content)
      @tag = tag
      @fetched_content = fetched_content
    end

    def detected_new_tag_version?
      if @fetched_content.nil?
        Rails.logger.error "`NewTagVersionDetector` `detected_new_tag_version?` called with @fetched_content of `nil`, skipping..."
        return false
      else
        return true if @tag.has_no_versions?
        auto_set_bytesize_changes_flag_based_on_tag_version_frequency_if_necessary!
        detected_new_tag_version_based_on_detection_configuration?
      end
    end

    def new_hashed_content
      @new_hashed_content ||= TagManager::Hasher.hash!(@fetched_content)
    end

    def bytesize_changed?
      # return nil unless should_detect_changes_based_on_bytesize_changes?
      @bytesize_changed ||= @fetched_content.bytesize != @tag.current_version.bytes
    end

    def hash_changed?
      # return nil if should_detect_changes_based_on_bytesize_changes?
      @hash_changed ||= new_hashed_content != @tag.current_version.hashed_content
    end

    def content_has_detectable_changes?
      return true if Util.env_is_true('DONT_REQUIRE_DETECTABLE_DIFFERENCES_IN_CONTENT_FOR_NEW_TAG_VERSION_DETECTION')
      @content_has_detectable_changes ||= DiffAnalyzer.new(new_content: @fetched_content, previous_content: @tag.current_version.content).total_changes > 0
    end

    # TODO: how can we group many tag versions to indicate there's several currently released tag versions
    # and detect when a new version is released outside of that set?
    def fetched_content_is_the_same_as_a_previous_version?
      # does this tag have a tag version with the same content that was created within the last 14 days?
      # if it's older than 14 days ago then it will be considered a new tag version
      return true if Util.env_is_true('DONT_CHECK_IF_TAG_HAS_SAME_CONTENT_IN_PREVIOUS_RELEASE_FOR_NEW_TAG_VERSION_DETECTION')
      @fetched_content_is_the_same_as_a_previous_version ||= @tag.tag_versions.more_recent_than(14.days.ago).where(hashed_content: new_hashed_content).exists?
    end

    private

    def detected_new_tag_version_based_on_detection_configuration?
      return false if !content_has_detectable_changes?
      return false if fetched_content_is_the_same_as_a_previous_version?
      should_detect_changes_based_on_bytesize_changes? ? bytesize_changed? : hash_changed?
    end

    def auto_set_bytesize_changes_flag_based_on_tag_version_frequency_if_necessary!
      return unless Util.env_is_true('AUTO_DETECT_TAG_VERSION_BYTE_SIZE_CHANGES')
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
  end
end
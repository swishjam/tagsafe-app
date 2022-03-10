module TagManager
  class NewTagVersionDetector
    def initialize(tag, fetched_content)
      @tag = tag
      @fetched_content = fetched_content
    end

    def detected_new_tag_version?
      return @detected_new_tag_version if defined?(@detected_new_tag_version)
      @detected_new_tag_version ||= begin
        return true if @tag.has_no_versions?
        auto_set_bytesize_changes_flag_based_on_tag_version_frequency_if_necessary!
        detected_new_tag_version_based_on_detection_configuration?
      end
    end

    def new_hashed_content
      return @new_hashed_content if defined?(@new_hashed_content)
      @new_hashed_content ||= begin
        return if @fetched_content.nil?
        TagManager::Hasher.hash!(@fetched_content)
      end
    end

    def bytesize_changed?
      return @bytesize_changed if defined?(@bytesize_changed)
      @bytesize_changed ||= begin
        return true if @tag.has_no_versions?
        return false if @fetched_content.nil?
        @fetched_content.bytesize != @tag.current_version.bytes
      end
    end

    def hash_changed?
      return @hash_changed if defined?(@hash_changed)
      @hash_changed ||= begin
        return true if @tag.has_no_versions?
        return false if @fetched_content.nil?
        new_hashed_content != @tag.current_version.hashed_content
      end
    end

    def content_has_detectable_changes?
      return @content_has_detectable_changes if defined?(@content_has_detectable_changes)
      @content_has_detectable_changes ||= begin
        return true if @tag.has_no_versions?
        return false if @fetched_content.nil?
        return true if Util.env_is_true('DONT_REQUIRE_DETECTABLE_DIFFERENCES_IN_CONTENT_FOR_NEW_TAG_VERSION_DETECTION')
        DiffAnalyzer.new(new_content: @fetched_content, previous_content: @tag.current_version.content, num_lines_of_context: 0).total_changes > 0
      end
    end

    # TODO: how can we group many tag versions to indicate there's several currently released tag versions
    # and detect when a new version is released outside of that set?
    def fetched_content_is_the_same_as_a_previous_version?
      return @fetched_content_is_the_same_as_a_previous_version if defined?(@fetched_content_is_the_same_as_a_previous_version)
      @fetched_content_is_the_same_as_a_previous_version ||= begin
        return false if Util.env_is_true('DONT_CHECK_IF_TAG_HAS_SAME_CONTENT_IN_PREVIOUS_RELEASE_FOR_NEW_TAG_VERSION_DETECTION')
        @tag.tag_versions.most_recent_first.where(hashed_content: new_hashed_content).limit(5).any?
      end
    end

    private

    def detected_new_tag_version_based_on_detection_configuration?
      return @detected_new_tag_version_based_on_detection_configuration if defined?(@detected_new_tag_version_based_on_detection_configuration)
      @detected_new_tag_version_based_on_detection_configuration ||= begin
        return false if !content_has_detectable_changes?
        return false if fetched_content_is_the_same_as_a_previous_version?
        should_detect_changes_based_on_bytesize_changes? ? bytesize_changed? : hash_changed?
      end
    end

    def auto_set_bytesize_changes_flag_based_on_tag_version_frequency_if_necessary!
      return if @fetched_content.nil?
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
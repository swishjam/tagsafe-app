module TagManager
  class Evaluator
    attr_accessor :tag_version

    def initialize(tag)
      @tag = tag
    end

    def evaluate!
      update_tag_check_with_tag_version_detection_results!
      if tag_released_new_tag_version?
        tag_version = capture_new_tag_version!
        unless Util.env_is_true('SEND_NEW_TAG_VERSION_NOTIFICATIONS_IN_NEW_TAG_VERSION_JOB_INSTEAD_OF_TAG_CHECK_INTERVAL_JOB')
          NotificationModerator::NewTagVersionNotifier.new(tag_version).notify!
        end
      end
    end

    def tag_released_new_tag_version?
      @tag_changed ||= tag_version_detector.detected_new_tag_version?
    end

    private

    def capture_new_tag_version!
      TagManager::TagVersionCapturer.new(
        tag: @tag, 
        content: fetched_tag_content,
        tag_check: fetcher.tag_check,
        hashed_content: tag_version_detector.new_hashed_content
      ).capture_new_tag_version!
    end

    def update_tag_check_with_tag_version_detection_results!
      fetch_tag_content!
      fetcher.tag_check.update!(
        content_has_detectable_changes: tag_version_detector.content_has_detectable_changes?,
        content_is_the_same_as_a_previous_version: tag_version_detector.fetched_content_is_the_same_as_a_previous_version?,
        bytesize_changed: tag_version_detector.bytesize_changed?,
        hash_changed: tag_version_detector.hash_changed?
      )
    end

    def fetched_tag_content
      @tag_content ||= fetcher.fetch!
    end
    alias fetch_tag_content! fetched_tag_content

    def fetcher
      @fetcher ||= TagManager::ContentFetcher.new(@tag)
    end

    def tag_version_detector
      @tag_version_detector ||= TagManager::NewTagVersionDetector.new(@tag, fetched_tag_content)
    end
  end
end
module TagManager
  class Evaluator
    attr_accessor :tag_version

    def initialize(tag)
      @tag = tag
    end

    def evaluate!
      if tag_changed?
        tag_version = TagManager::TagVersionCapturer.new(
          @tag, 
          fetched_tag_content,
          hashed_content: tag_version_detector.new_hashed_content
        ).capture_new_tag_version!
        unless ENV['SEND_NEW_TAG_VERSION_NOTIFICATIONS_IN_NEW_TAG_VERSION_JOB'] == 'true'
          NotificationModerator::NewTagVersionNotifier.new(tag_version).notify!
        end
      end
    end

    def tag_changed?
      @tag_changed ||= tag_version_detector.detected_new_tag_version?
    end

    private

    def fetched_tag_content
      @tag_content ||= fetcher.fetch!
    end

    def fetcher
      @fetcher ||= TagManager::ContentFetcher.new(@tag)
    end

    def tag_version_detector
      @tag_version_detector ||= TagManager::NewTagVersionDetector.new(@tag, fetched_tag_content)
    end
  end
end
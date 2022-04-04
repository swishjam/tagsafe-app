# module TagManager
#   class Evaluator
#     attr_accessor :tag_version, :tag_check

#     def initialize(tag)
#       @tag = tag
#     end

#     def evaluate!
#       sentry_transaction = Sentry.start_transaction(op: "TagManager::Evalutor.evaluate!")
#       fetch_tag_content!
#       capture_tag_check_if_necessary!
#       if fetched_tag_content.nil?
#         @tag.update!(has_content: false) if @tag.has_content
#       elsif detected_new_tag_version?
#         @tag.update!(has_content: true) unless @tag.has_content
#         capture_new_tag_version!
#       end
#       sentry_transaction.finish
#     end

#     def detected_new_tag_version?
#       @detected_new_tag_version ||= tag_version_detector.detected_new_tag_version?
#     end

#     private

#     def capture_new_tag_version!
#       TagManager::TagVersionCapturer.new(
#         tag: @tag, 
#         content: fetched_tag_content,
#         tag_check: captured_tag_check,
#         hashed_content: tag_version_detector.new_hashed_content
#       ).capture_new_tag_version!
#     end

#     def capture_tag_check_if_necessary!
#       @tag_check ||= begin
#         return unless @tag.tag_preferences.should_log_tag_checks
#         @tag.tag_checks.create!(
#           response_time_ms: fetcher.response_time_ms, 
#           response_code: fetcher.response_code,
#           captured_new_tag_version: tag_version_detector.detected_new_tag_version?,
#           content_has_detectable_changes: tag_version_detector.content_has_detectable_changes?,
#           content_is_the_same_as_a_previous_version: tag_version_detector.fetched_content_is_the_same_as_a_previous_version?,
#           bytesize_changed: tag_version_detector.bytesize_changed?,
#           hash_changed: tag_version_detector.hash_changed?
#         )
#       end
#     end
#     alias captured_tag_check capture_tag_check_if_necessary!

#     def fetch_tag_content!
#       @tag_content ||= fetcher.fetch!
#     end
#     alias fetched_tag_content fetch_tag_content!

#     def fetcher
#       @fetcher ||= TagManager::ContentFetcher.new(@tag)
#     end

#     def tag_version_detector
#       @tag_version_detector ||= TagManager::NewTagVersionDetector.new(@tag, fetched_tag_content, @tag.current_version)
#     end
#   end
# end
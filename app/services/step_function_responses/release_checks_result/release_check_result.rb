module StepFunctionResponses
  class ReleaseChecksResult
    class ReleaseCheckResult
      class InvalidReleaseCheckResponse < StandardError; end;
      def initialize(release_check_result_hash, release_check_batch_id)
        @uptime_check_result = release_check_result_hash
        @release_check_batch_id = release_check_batch_id
      end

      def formatted_for_create
        {
          created_at: DateTime.now,
          updated_at: DateTime.now,
          executed_at: datetime_performed_at,
          tag_id: tag_id,
          release_check_batch_id: @release_check_batch_id,
          # uid: '',
          bytesize_changed: bytesize_changed,
          hash_changed: hash_changed,
          content_is_the_same_as_a_previous_version: content_is_the_same_as_a_previous_version,
          captured_new_tag_version: captured_new_tag_version
        }
      end

      def tag_id
        @uptime_check_result['tag_id']
      end

      def tag
        @tag ||= Tag.find(tag_id)
      rescue ActiveRecord::RecordNotFound => e
        raise InvalidReleaseCheckResponse, "Cannot find Tag with an id of `#{tag_id}` in ReleaseCheck response, Lambda data store may be stale."
      end

      def datetime_performed_at
        @datetime_performed_at ||= Time.at(@uptime_check_result['ts'] / 1_000).to_datetime
      end

      def bytesize_changed
        @uptime_check_result.dig('bytes', 'changed')
      end

      def hash_changed
        @uptime_check_result.dig('hashed_content', 'changed')
      end

      def content_is_the_same_as_a_previous_version
        @uptime_check_result.dig('hashed_content', 'has_same_hashed_content_in_recent_version')
      end

      def response_time_ms
        @uptime_check_result.dig('fetch_details', 'response_ms')
      end

      def response_code
        @uptime_check_result.dig('fetch_details', 'response_code')
      end

      def captured_new_tag_version
        @uptime_check_result.dig('found_new_version')
      end

      def new_hashed_content
        @uptime_check_result.dig('hashed_content', 'new_hashed_content')
      end

      def new_bytesize
        @uptime_check_result.dig('bytes', 'new_byte_size')
      end

      def new_tag_version_s3_url
        @uptime_check_result.dig('new_version_s3_url')
      end

      def new_content
        return unless new_tag_version_s3_url.present?
        @new_content ||= TagsafeAws::S3.get_object_by_s3_url(new_tag_version_s3_url).body.read
      end
    end
  end
end
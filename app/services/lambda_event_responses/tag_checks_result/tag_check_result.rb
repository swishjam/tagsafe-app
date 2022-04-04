module LambdaEventResponses
  class TagChecksResult
    class TagCheckResult
      class InvalidTagCheckResponse < StandardError; end;
      attr_accessor :aws_region

      def initialize(tag_check_result_hash, aws_region:)
        @tag_check_result = tag_check_result_hash
        @aws_region = aws_region
      end

      def formatted_for_create
        {
          created_at: datetime_performed_at,
          tag_id: tag_id,
          # uid: '',
          response_time_ms: response_time_ms,
          response_code: response_code,
          bytesize_changed: bytesize_changed,
          hash_changed: hash_changed,
          content_is_the_same_as_a_previous_version: content_is_the_same_as_a_previous_version,
          captured_new_tag_version: captured_new_tag_version,
          tag_check_region_id: tag_check_region.id
        }
      end

      def tag_id
        @tag_check_result['tag_id']
      end

      def tag
        @tag ||= Tag.find(tag_id)
      rescue ActiveRecord::RecordNotFound => e
        raise InvalidTagCheckResponse, "Cannot find Tag with an id of `#{tag_id}` in TagCheck response, Lambda data store may be stale."
      end

      def should_measure_uptime?
        tag.tag_preferences.should_log_tag_checks
      end

      def tag_check_region
        @tag_check_region ||= TagCheckRegion.find_by(aws_name: aws_region)
      end

      def datetime_performed_at
        @datetime_performed_at ||= Time.at(@tag_check_result['ts'] / 1_000).to_datetime
      end

      def bytesize_changed
        @tag_check_result.dig('bytes', 'changed')
      end

      def hash_changed
        @tag_check_result.dig('hashed_content', 'changed')
      end

      def content_is_the_same_as_a_previous_version
        @tag_check_result.dig('hashed_content', 'has_same_hashed_content_in_recent_version')
      end

      def response_time_ms
        return nil unless should_measure_uptime?
        @tag_check_result.dig('fetch_details', 'response_ms')
      end

      def response_code
        return nil unless should_measure_uptime?
        @tag_check_result.dig('fetch_details', 'response_code')
      end

      def captured_new_tag_version
        @tag_check_result.dig('found_new_version')
      end

      def new_hashed_content
        @tag_check_result.dig('hashed_content', 'new_hashed_content')
      end

      def new_bytesize
        @tag_check_result.dig('bytes', 'new_byte_size')
      end

      def new_tag_version_s3_url
        @tag_check_result.dig('new_version_s3_url')
      end

      def new_content
        return unless new_tag_version_s3_url.present?
        @new_content ||= TagsafeAws::S3.get_object_by_s3_url(new_tag_version_s3_url).body.read
      end
    end
  end
end
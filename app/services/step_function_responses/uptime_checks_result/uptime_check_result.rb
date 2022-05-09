module StepFunctionResponses
  class UptimeChecksResult
    class UptimeCheckResult
      attr_accessor :aws_region

      def initialize(uptime_check_result_hash, aws_region:)
        @uptime_check_result = uptime_check_result_hash
        @aws_region = aws_region
      end

      def formatted_for_create
        {
          created_at: DateTime.now,
          executed_at: datetime_performed_at,
          tag_id: tag_id,
          # uid: '',
          response_time_ms: response_time_ms,
          response_code: response_code,
          uptime_region_id: uptime_region.id
        }
      end

      def tag_id
        @uptime_check_result['tag_id']
      end

      def tag
        @tag ||= Tag.find(tag_id)
      rescue ActiveRecord::RecordNotFound => e
        raise StandardError, "Cannot find Tag with an id of `#{tag_id}` in ReleaseCheck response, Lambda data store may be stale."
      end

      def uptime_region
        @uptime_region ||= UptimeRegion.find_by(aws_name: aws_region)
      end

      def datetime_performed_at
        @datetime_performed_at ||= Time.at(@uptime_check_result['ts'] / 1_000).to_datetime
      end

      def response_time_ms
        @uptime_check_result.dig('fetch_details', 'response_ms')
      end

      def response_code
        @uptime_check_result.dig('fetch_details', 'response_code')
      end
    end
  end
end
module StepFunctionResponses
  class TestRunResult
    class PuppeteerRecording
      def initialize(screen_recording_hash)
        @screen_recording_hash = screen_recording_hash
      end

      def present?
        @present ||= @screen_recording_hash['s3_url'] || @screen_recording_hash['failed_to_capture']
      end

      def formatted
        {
          s3_url: s3_url,
          ms_to_stop_recording: ms_to_stop,
          ms_available_to_stop_within: ms_available_to_stop_within
        }
      end

      def s3_url
        @s3_url ||= @screen_recording_hash['s3_url'] || PuppeteerRecording::FAILED_TO_CAPTURE_S3_URL_VALUE
      end

      def ms_to_stop
        @ms_to_stop ||= @screen_recording_hash['ms_to_stop']
      end

      def ms_available_to_stop_within
        @ms_available_to_stop_within ||= @screen_recording_hash['stop_ms_threshold']
      end
    end
  end
end
module LambdaEventResponses
  class PerformanceAuditResult
    class PuppeteerRecording
      def initialize(screen_recording_hash)
        @screen_recording_hash = screen_recording_hash
      end

      def included_and_valid?
        !s3_url.nil?
      end

      def formatted_results
        {
          s3_url: s3_url,
          ms_to_stop_recording: ms_to_stop_recording,
          ms_available_to_stop_within: ms_available_to_stop_within
        }
      end

      def s3_url
        @s3_url ||= @screen_recording_hash['s3_url']
      end

      def ms_to_stop_recording
        @ms_to_stop_recording ||= @screen_recording_hash['ms_to_stop_recording']
      end

      def ms_available_to_stop_within
        @ms_available_to_stop_within ||= @screen_recording_hash['ms_available_to_stop_within']
      end
    end
  end
end
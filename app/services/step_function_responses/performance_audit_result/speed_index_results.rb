module StepFunctionResponses
  class PerformanceAuditResult
    class SpeedIndexResults
      def initialize(speed_index_results_hash)
        @speed_index_results_hash = speed_index_results_hash
      end

      def failed?
        error_message.present?
      end

      def error_message
        @speed_index_results_hash['error_message']
      end

      def speed_index
        @speed_index_results_hash['speed_index']
      end

      def perceptual_speed_index
        @speed_index_results_hash['perceptual_speed_index']
      end

      def ms_until_first_visual_change
        @speed_index_results_hash['ms_before_first_visual_change']
      end

      def ms_until_last_visual_change
        @speed_index_results_hash['ms_before_last_visual_change']
      end

      def frames
        @speed_index_results_hash['frame_screenshots'] || []
      end

      def formatted_frames(performance_audit_id)
        frames.map{ |frame| frame.merge!(performance_audit_id: performance_audit_id) }
      end
    end
  end
end
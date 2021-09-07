module GeppettoModerator
  module Receivers
    class PerformanceAuditCompleted
      def initialize(error:, results_with_tag:, results_without_tag:, audit_id:, num_attempts:)
        @error = error
        @audit_id = audit_id
        @results_with_tag = results_with_tag
        @results_without_tag = results_without_tag
        @num_attempts = num_attempts
      end
    
      def receive!
        PerformanceAuditCompletedJob.perform_later(
          error: @error,
          results_with_tag: @results_with_tag,
          results_without_tag: @results_without_tag,
          audit_id: @audit_id,
          num_attempts: @num_attempts
        )
      end
    end
  end
end
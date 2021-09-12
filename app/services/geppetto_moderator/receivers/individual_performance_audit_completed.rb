module GeppettoModerator
  module Receivers
    class IndividualPerformanceAuditCompleted
      def initialize(individual_performance_audit_id:, results:, logs:, error:)
        @individual_performance_audit_id = individual_performance_audit_id
        @results = results
        @logs = logs
        @error = error
      end
    
      def receive!
        IndividualPerformanceAuditCompletedJob.perform_later(
          individual_performance_audit_id: @individual_performance_audit_id,
          results: @results,
          logs: @logs,
          error: @error
        )
      end
    end
  end
end
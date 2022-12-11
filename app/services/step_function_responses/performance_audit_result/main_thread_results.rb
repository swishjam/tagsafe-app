module StepFunctionResponses
  class PerformanceAuditResult
    class MainThreadResults
      def initialize(main_thread_results_hash)
        @main_thread_results_hash = main_thread_results_hash
      end

      def total_main_thread_execution_ms_for_tag
        @main_thread_results_hash['total_main_thread_execution_ms_for_tag'] || 0
      end

      def total_main_thread_blocking_execution_ms_for_tag
        @main_thread_results_hash['total_main_thread_blocking_execution_ms_for_tag'] || 0
      end

      # currently only used for domain audits?
      def entire_main_thread_execution_ms
        @main_thread_results_hash['entire_main_thread_executions_ms'] || 0
      end

      # currently only used for domain audits?
      def entire_main_thread_blocking_executions_ms
        @main_thread_results_hash['entire_main_thread_blocking_executions_ms'] || 0
      end
    end
  end
end